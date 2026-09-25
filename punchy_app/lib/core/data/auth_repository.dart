import '../api/api_client.dart';

/// Single boundary for authentication/account APIs. UI and providers should
/// depend on this contract rather than constructing endpoint paths themselves.
class AuthRepository {
  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> login(String email, String password) async =>
      _asMap(
        await _client.post('/auth/login', {
          'email': email,
          'password': password,
        }),
      );

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async =>
      _asMap(
        await _client.post('/auth/refresh', {'refreshToken': refreshToken}),
      );

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    String? name,
    String? phone,
    String? countryCode,
  }) async => _asMap(
    await _client.post('/auth/register', {
      'email': email,
      'password': password,
      'role': role,
      if (name != null && name.isNotEmpty) 'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'countryCode': ?countryCode,
    }),
  );

  Future<Map<String, dynamic>> verifySignup(String email, String otp) async =>
      _asMap(
        await _client.post('/auth/verify-signup', {'email': email, 'otp': otp}),
      );

  Future<Map<String, dynamic>> profile() async =>
      _asMap(await _client.get('/auth/me'));

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
  }) async => _asMap(
    await _client.put('/auth/profile', {
      'name': name,
      ...?phone == null ? null : {'phone': phone},
    }),
  );

  Future<void> registerDeviceToken(String token) =>
      _client.post('/auth/device-token', {'token': token});

  Future<void> setNotificationPreference(bool enabled) =>
      _client.post('/auth/notification-preference', {'enabled': enabled});

  Future<void> requestPasswordReset(String email) =>
      _client.post('/auth/forgot-password', {'email': email});

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) => _client.post('/auth/reset-password', {
    'email': email,
    'otp': otp,
    'password': password,
  });

  Future<void> requestDeleteAccountOtp() =>
      _client.post('/auth/account/delete-request', {});

  Future<void> deleteAccount(String otp) =>
      _client.deleteWithBody('/auth/account', {'otp': otp});

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic>
      ? value
      : Map<String, dynamic>.from(value as Map);
}
