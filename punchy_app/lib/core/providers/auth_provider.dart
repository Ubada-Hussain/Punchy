import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_client.dart';
import '../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _auth = AuthRepository();
  final TokenStore _tokenStore = const SecureTokenStore();
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isReady = false;
  bool get isReady => _isReady;

  String? _errorMessage;
  Map<String, dynamic>? _pendingSignup;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get pendingSignup => _pendingSignup;

  String? _token;
  bool get isAuthenticated => _token != null;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  bool _isSuspended = false;
  bool _isMaintenance = false;
  bool get isMaintenance => _isMaintenance;
  bool get isSuspended {
    if (_isSuspended) return true;
    if (_user != null) {
      if (_user!['isSuspended'] == true) return true;
      if (_user!['isBlocked'] == true) return true;
      if (_user!['role'] == 'BUSINESS' &&
          _user!['businessProfile']?['status'] == 'SUSPENDED') {
        return true;
      }
      if (_user!['role'] == 'STAFF' &&
          _user!['staffBusiness']?['status'] == 'SUSPENDED') {
        return true;
      }
    }
    return false;
  }

  bool get isStaff => _user?['role'] == 'STAFF';
  bool get isStaffActive => _user?['isStaffActive'] ?? true;
  String? get businessName =>
      _user?['businessName'] ??
      _user?['businessProfile']?['name'] ??
      _user?['staffBusiness']?['name'];

  AuthProvider() {
    _loadToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (isAuthenticated && token.isNotEmpty) {
        try {
          await _auth.registerDeviceToken(token);
        } catch (e) {
          debugPrint('FCM token refresh registration failed: $e');
        }
      }
    });
  }

  Future<void> _loadToken() async {
    try {
      _token = await _tokenStore.read();
      if (_token == null) {
        // One-time migration for users upgrading from the legacy plaintext
        // SharedPreferences token. The legacy value is removed immediately.
        final legacyPrefs = await SharedPreferences.getInstance();
        final legacyToken = legacyPrefs.getString('token');
        if (legacyToken != null && legacyToken.isNotEmpty) {
          await _tokenStore.write(legacyToken);
          await legacyPrefs.remove('token');
          _token = legacyToken;
        }
      }
      if (_token != null) {
        await fetchProfile();
        if (_token != null) await _registerDeviceToken();
      }
      // Health/maintenance is supplemental and must not delay login or the
      // first route when no session exists.
      unawaited(checkMaintenance());
    } catch (e) {
      debugPrint('AuthProvider _loadToken error: $e');
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> checkMaintenance() async {
    try {
      final res = await _api.get('/health');
      _isMaintenance = res is Map && res['maintenance'] == true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    await _auth.setNotificationPreference(enabled);
  }

  Future<void> fetchProfile() async {
    try {
      final res = await _auth.profile();
      if (res['user'] != null) {
        _user = res['user'];
        _isMaintenance = false;
        _isSuspended =
            _user?['isSuspended'] == true || _user?['isBlocked'] == true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider fetchProfile error: $e');
      if (e is ApiException && e.statusCode == 401) {
        await _tokenStore.delete();
        _token = null;
        _user = null;
        _isSuspended = false;
        notifyListeners();
        return;
      }
      if (e is ApiException && e.statusCode == 403) {
        _isSuspended = true;
        notifyListeners();
      }
      if (e is ApiException && e.statusCode == 503) {
        _isMaintenance =
            e.details?['maintenance'] == true ||
            e.message.toLowerCase().contains('maintenance');
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuspended = false;
    notifyListeners();

    try {
      final response = await _auth.login(email, password);

      _token = response['accessToken'];
      _user = response['user'];
      _isSuspended =
          _user?['isSuspended'] == true || _user?['isBlocked'] == true;

      await _tokenStore.write(_token!);
      // Refresh the complete server profile so generated fields (including
      // the immutable public ID) are available immediately after sign-in.
      await fetchProfile();
      await _registerDeviceToken();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
        if (e.statusCode == 403 ||
            e.message.toLowerCase().contains('suspend') ||
            e.message.toLowerCase().contains('blocked')) {
          _isSuspended = true;
        }
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _auth.registerDeviceToken(token);
      }
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.requestPasswordReset(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e is ApiException
          ? e.message
          : 'Could not send reset code. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.resetPassword(email: email, otp: otp, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e is ApiException
          ? e.message
          : 'Could not reset password. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String role,
    String? name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuspended = false;
    notifyListeners();

    try {
      final response = await _auth.register(
        email: email,
        password: password,
        role: role,
        name: name,
        phone: phone,
      );

      if (response['verificationRequired'] == true) {
        _pendingSignup = {'email': email};
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _token = response['accessToken'];
      _user = response['user'];

      await _tokenStore.write(_token!);
      await _registerDeviceToken();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifySignup(String otp) async {
    final email = _pendingSignup?['email']?.toString();
    if (email == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _auth.verifySignup(email, otp);
      _token = response['accessToken'];
      _user = response['user'];
      _pendingSignup = null;
      await _tokenStore.write(_token!);
      await _registerDeviceToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e is ApiException ? e.message : 'Verification failed.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({required String name, String? phone}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _auth.updateProfile(name: name, phone: phone);

      if (res['user'] != null) {
        _user = res['user'];
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setStaffActiveState(bool active) {
    if (_user != null) {
      _user!['isStaffActive'] = active;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _tokenStore.delete();
    _token = null;
    _user = null;
    _isSuspended = false;
    notifyListeners();
  }

  Future<bool> requestDeleteAccountOtp() async {
    try {
      await _auth.requestDeleteAccountOtp();
      return true;
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Could not send verification code.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(String otp) async {
    try {
      await _auth.deleteAccount(otp);
      await logout();
      return true;
    } catch (_) {
      return false;
    }
  }
}
