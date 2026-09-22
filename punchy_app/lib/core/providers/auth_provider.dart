import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_client.dart';
import '../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _auth = AuthRepository();
  final SecureTokenStore _tokenStore = const SecureTokenStore();
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isReady = false;
  bool get isReady => _isReady;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

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
      final cachedUserStr = await _tokenStore.readCachedUser();
      if (cachedUserStr != null && cachedUserStr.isNotEmpty) {
        try {
          _user = jsonDecode(cachedUserStr) as Map<String, dynamic>;
        } catch (_) {}
      }

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
      } else {
        // No session stored, verify server reachability without blocking
        try {
          await _api.get('/health');
          _isOffline = false;
        } catch (e) {
          if (e is NetworkException || e is SocketException || e is TimeoutException) {
            _isOffline = true;
          }
        }
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
      _isOffline = false;
      notifyListeners();
    } catch (e) {
      if (e is NetworkException || e is SocketException || e is TimeoutException) {
        _isOffline = true;
        notifyListeners();
      }
    }
  }

  Future<bool> retryConnection() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/health');
      _isMaintenance = res is Map && res['maintenance'] == true;
      _isOffline = false;
      if (_token != null) {
        await fetchProfile();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is NetworkException || e is SocketException || e is TimeoutException) {
        _isOffline = true;
      } else {
        _isOffline = false;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
        _isOffline = false;
        _isSuspended =
            _user?['isSuspended'] == true || _user?['isBlocked'] == true;
        await _tokenStore.writeCachedUser(jsonEncode(_user));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider fetchProfile error: $e');
      if (e is NetworkException) {
        _isOffline = true;
        notifyListeners();
        return;
      }
      if (e is ApiException && e.statusCode == 401) {
        // Attempt token refresh before clearing
        final refreshToken = await _tokenStore.readRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          try {
            final refreshed = await _auth.refreshToken(refreshToken);
            if (refreshed['accessToken'] != null) {
              _token = refreshed['accessToken'];
              await _tokenStore.write(_token!);
              if (refreshed['refreshToken'] != null) {
                await _tokenStore.writeRefreshToken(refreshed['refreshToken'].toString());
              }
              if (refreshed['user'] != null) {
                _user = refreshed['user'];
                await _tokenStore.writeCachedUser(jsonEncode(_user));
              }
              _isOffline = false;
              _isSuspended = false;
              notifyListeners();
              return;
            }
          } catch (refreshErr) {
            debugPrint('Token refresh failed: $refreshErr');
          }
        }
        await _tokenStore.clearAll();
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
      final refreshToken = response['refreshToken'];
      _user = response['user'];
      _isSuspended =
          _user?['isSuspended'] == true || _user?['isBlocked'] == true;
      _isOffline = false;

      await _tokenStore.write(_token!);
      if (refreshToken != null && refreshToken.toString().isNotEmpty) {
        await _tokenStore.writeRefreshToken(refreshToken.toString());
      }
      if (_user != null) {
        await _tokenStore.writeCachedUser(jsonEncode(_user));
      }

      // Refresh the complete server profile so generated fields (including
      // the immutable public ID) are available immediately after sign-in.
      await fetchProfile();
      await _registerDeviceToken();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is NetworkException) {
        _isOffline = true;
        _errorMessage = e.message;
      } else if (e is ApiException) {
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
      final refreshToken = response['refreshToken'];
      _user = response['user'];
      _isOffline = false;

      await _tokenStore.write(_token!);
      if (refreshToken != null && refreshToken.toString().isNotEmpty) {
        await _tokenStore.writeRefreshToken(refreshToken.toString());
      }
      if (_user != null) {
        await _tokenStore.writeCachedUser(jsonEncode(_user));
      }
      await _registerDeviceToken();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is NetworkException) {
        _isOffline = true;
        _errorMessage = e.message;
      } else if (e is ApiException) {
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
      final refreshToken = response['refreshToken'];
      _user = response['user'];
      _pendingSignup = null;
      _isOffline = false;

      await _tokenStore.write(_token!);
      if (refreshToken != null && refreshToken.toString().isNotEmpty) {
        await _tokenStore.writeRefreshToken(refreshToken.toString());
      }
      if (_user != null) {
        await _tokenStore.writeCachedUser(jsonEncode(_user));
      }
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
        await _tokenStore.writeCachedUser(jsonEncode(_user));
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
    await _tokenStore.clearAll();
    _token = null;
    _user = null;
    _isSuspended = false;
    _isOffline = false;
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
