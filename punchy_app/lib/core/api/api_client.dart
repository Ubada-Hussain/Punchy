import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  // Share one connection pool across screens so navigation does not pay a new
  // DNS/TCP/TLS handshake for every page-level API client.
  static final http.Client _sharedClient = http.Client();

  /// Requests that change server state are coalesced while they are in flight.
  /// This is a last line of defence for rapid taps from separate controls that
  /// initiate the exact same action.
  static final Map<String, Future<dynamic>> _pendingMutations = {};

  ApiClient({
    http.Client? client,
    String? baseUrl,
    TokenStore? tokenStore,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? _sharedClient,
       _tokenStore = tokenStore ?? const SecureTokenStore(),
       baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'PUNCHY_API_URL',
             defaultValue: 'https://trypunchy.site/api',
           );

  final http.Client _client;
  final TokenStore _tokenStore;
  final String baseUrl;
  final Duration timeout;

  Future<T> _execute<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException catch (_) {
      throw const NetworkException(
        'Unable to connect. Please check your internet connection.',
      );
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on TimeoutException catch (_) {
      throw const NetworkException('Connection timed out. Please try again.');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStore.read();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    return _runMutation(
      'POST',
      endpoint,
      body,
      () => _execute(() async {
        final response = await _client
            .post(
              _uri(endpoint),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(timeout);
        return _handleResponse(response);
      }),
    );
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    return _runMutation(
      'PUT',
      endpoint,
      body,
      () => _execute(() async {
        final response = await _client
            .put(
              _uri(endpoint),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(timeout);
        return _handleResponse(response);
      }),
    );
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    return _runMutation(
      'PATCH',
      endpoint,
      body,
      () => _execute(() async {
        final response = await _client
            .patch(
              _uri(endpoint),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(timeout);
        return _handleResponse(response);
      }),
    );
  }

  Future<dynamic> delete(String endpoint) async {
    return _runMutation(
      'DELETE',
      endpoint,
      null,
      () => _execute(() async {
        final response = await _client
            .delete(_uri(endpoint), headers: await _getHeaders())
            .timeout(timeout);
        return _handleResponse(response);
      }),
    );
  }

  Future<dynamic> deleteWithBody(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _runMutation(
      'DELETE',
      endpoint,
      body,
      () => _execute(() async {
        final response = await _client
            .delete(
              _uri(endpoint),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(timeout);
        return _handleResponse(response);
      }),
    );
  }

  Future<dynamic> _runMutation(
    String method,
    String endpoint,
    Map<String, dynamic>? body,
    Future<dynamic> Function() request,
  ) {
    final key =
        '$baseUrl|$method|$endpoint|${body == null ? '' : jsonEncode(body)}';
    final pending = _pendingMutations[key];
    if (pending != null) return pending;

    late final Future<dynamic> operation;
    operation = request().whenComplete(() {
      if (identical(_pendingMutations[key], operation)) {
        _pendingMutations.remove(key);
      }
    });
    _pendingMutations[key] = operation;
    return operation;
  }

  Future<dynamic> get(String endpoint) async {
    return _execute(() async {
      final response = await _client
          .get(_uri(endpoint), headers: await _getHeaders())
          .timeout(timeout);
      return _handleResponse(response);
    });
  }

  Future<dynamic> uploadImage(
    String endpoint,
    File file, {
    String field = 'logo',
  }) async {
    return _execute(() async {
      final request = http.MultipartRequest('POST', _uri(endpoint));
      final headers = await _getHeaders();
      // MultipartRequest generates its own boundary Content-Type. Sending the
      // JSON header here makes Express/Multer see an empty request body.
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      // Some Android gallery providers return a cache path without a useful
      // extension. Give the multipart part an explicit image filename so
      // Multer can reliably identify it as the `logo` file.
      final fileName =
          file.uri.pathSegments.isNotEmpty &&
              file.uri.pathSegments.last.contains('.')
          ? file.uri.pathSegments.last
          : 'logo.jpg';
      request.files.add(
        await http.MultipartFile.fromPath(
          field,
          file.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      return _handleResponse(
        await http.Response.fromStream(await request.send().timeout(timeout)),
      );
    });
  }

  Uri _uri(String endpoint) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';
    return Uri.parse('$normalizedBase$normalizedEndpoint');
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      var message = response.body;
      Map<String, dynamic>? details;
      try {
        final v = jsonDecode(response.body);
        if (v is Map) {
          details = Map<String, dynamic>.from(v);
          if (v['error'] != null) message = v['error'].toString();
        }
      } catch (_) {}
      throw ApiException(response.statusCode, message, details: details);
    }
  }
}

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SharedPreferencesTokenStore implements TokenStore {
  const SharedPreferencesTokenStore();

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString('token');

  @override
  Future<void> write(String token) async =>
      (await SharedPreferences.getInstance()).setString('token', token);

  @override
  Future<void> delete() async =>
      (await SharedPreferences.getInstance()).remove('token');
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore();
  static const _storage = FlutterSecureStorage();
  static String? _cachedAccessToken;
  static bool _accessTokenLoaded = false;

  @override
  Future<String?> read() async {
    if (_accessTokenLoaded) return _cachedAccessToken;
    _cachedAccessToken = await _storage.read(key: 'access_token');
    _accessTokenLoaded = true;
    return _cachedAccessToken;
  }

  @override
  Future<void> write(String token) async {
    _cachedAccessToken = token;
    _accessTokenLoaded = true;
    await _storage.write(key: 'access_token', value: token);
  }

  @override
  Future<void> delete() async {
    _cachedAccessToken = null;
    _accessTokenLoaded = true;
    await _storage.delete(key: 'access_token');
  }

  Future<String?> readRefreshToken() => _storage.read(key: 'refresh_token');
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: 'refresh_token', value: token);
  Future<void> deleteRefreshToken() => _storage.delete(key: 'refresh_token');

  Future<String?> readCachedUser() => _storage.read(key: 'cached_user');
  Future<void> writeCachedUser(String userJson) =>
      _storage.write(key: 'cached_user', value: userJson);
  Future<void> deleteCachedUser() => _storage.delete(key: 'cached_user');

  Future<void> clearAll() async {
    _cachedAccessToken = null;
    _accessTokenLoaded = true;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'cached_user');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.statusCode, this.message, {this.details});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
