import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiClient {
  // Public production backend. localhost points to the emulator itself.
  static const String baseUrl = 'https://trypunchy.site/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> deleteWithBody(String endpoint, Map<String, dynamic> body) async {
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders(), body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> uploadImage(String endpoint, File file, {String field = 'logo'}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    final headers = await _getHeaders();
    // MultipartRequest generates its own boundary Content-Type. Sending the
    // JSON header here makes Express/Multer see an empty request body.
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    // Some Android gallery providers return a cache path without a useful
    // extension. Give the multipart part an explicit image filename so
    // Multer can reliably identify it as the `logo` file.
    final fileName = file.uri.pathSegments.isNotEmpty && file.uri.pathSegments.last.contains('.')
        ? file.uri.pathSegments.last
        : 'logo.jpg';
    request.files.add(await http.MultipartFile.fromPath(
      field,
      file.path,
      filename: fileName,
      contentType: MediaType('image', 'jpeg'),
    ));
    return _handleResponse(await http.Response.fromStream(await request.send()));
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

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;
  
  ApiException(this.statusCode, this.message, {this.details});
  
  @override
  String toString() => 'ApiException: $statusCode - $message';
}
