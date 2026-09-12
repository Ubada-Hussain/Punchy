import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:io';

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    TokenStore? tokenStore,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
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

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStore.read();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await _client
        .post(
          _uri(endpoint),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await _client
        .put(
          _uri(endpoint),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await _client
        .patch(
          _uri(endpoint),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await _client
        .delete(_uri(endpoint), headers: await _getHeaders())
        .timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> deleteWithBody(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .delete(
          _uri(endpoint),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final response = await _client
        .get(_uri(endpoint), headers: await _getHeaders())
        .timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> uploadImage(
    String endpoint,
    File file, {
    String field = 'logo',
  }) async {
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

  @override
  Future<String?> read() => _storage.read(key: 'access_token');

  @override
  Future<void> write(String token) =>
      _storage.write(key: 'access_token', value: token);

  @override
  Future<void> delete() => _storage.delete(key: 'access_token');
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.statusCode, this.message, {this.details});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
