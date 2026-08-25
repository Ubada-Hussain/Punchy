import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  String? _token;
  bool get isAuthenticated => _token != null;
  
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      await fetchProfile();
    }
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      final res = await _api.get('/auth/me');
      if (res != null && res['user'] != null) {
        _user = res['user'];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      
      _token = response['accessToken'];
      _user = response['user'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
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

  Future<bool> register({
    required String email,
    required String password,
    required String role,
    String? name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _api.post('/auth/register', {
        'email': email,
        'password': password,
        'role': role,
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      
      _token = response['accessToken'];
      _user = response['user'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
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

  Future<bool> updateProfile({required String name, String? phone}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.put('/auth/profile', {
        'name': name,
        ...?phone != null ? {'phone': phone} : null,
      });

      if (res != null && res['user'] != null) {
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

  Future<bool> loginWithClerk({
    required String email,
    String? name,
    String? provider,
    String? role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post('/auth/clerk', {
        'email': email,
        'name': name,
        'provider': provider ?? 'clerk',
        'role': role ?? 'CUSTOMER',
      });

      _token = response['accessToken'];
      _user = response['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    _user = null;
    notifyListeners();
  }
}
