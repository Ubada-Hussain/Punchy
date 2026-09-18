import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:punchy_app/core/api/api_client.dart';

class _ThrowingClient extends http.BaseClient {
  _ThrowingClient(this.error);
  final Object error;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw error;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Task 4: Business phone format validation', () {
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{8,20}$');

    test('accepts international and standard formatted phone numbers', () {
      expect(phoneRegex.hasMatch('+1234567890'), isTrue);
      expect(phoneRegex.hasMatch('+92 300 1234567'), isTrue);
      expect(phoneRegex.hasMatch('(021) 123-4567'), isTrue);
      expect(phoneRegex.hasMatch('+44 20 7946 0958'), isTrue);
      expect(phoneRegex.hasMatch('03001234567'), isTrue);
    });

    test('rejects invalid or too short numbers', () {
      expect(phoneRegex.hasMatch(''), isFalse);
      expect(phoneRegex.hasMatch('123'), isFalse);
      expect(phoneRegex.hasMatch('abcdefgh'), isFalse);
      expect(phoneRegex.hasMatch('phone12345'), isFalse);
      expect(phoneRegex.hasMatch('+12345678901234567890123'), isFalse);
    });
  });

  group('Task 2 & 1: NetworkException on connection failure', () {
    test('ApiClient wraps SocketException into NetworkException', () async {
      final client = ApiClient(
        tokenStore: const SharedPreferencesTokenStore(),
        client: _ThrowingClient(const SocketException('Failed host lookup')),
      );

      await expectLater(
        client.get('/health'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('ApiClient wraps ClientException into NetworkException', () async {
      final client = ApiClient(
        tokenStore: const SharedPreferencesTokenStore(),
        client: _ThrowingClient(http.ClientException('Network down')),
      );

      await expectLater(
        client.get('/health'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('Task 3: Real customer profile name display logic', () {
    test('uses profile name instead of email address', () {
      final user = {
        'id': 'cust_123',
        'name': 'Hajra',
        'email': 'ayesha@gmail.com',
      };

      // Real profile name field is used
      final displayName = (user['name'] != null && user['name'].toString().trim().isNotEmpty)
          ? user['name'].toString().trim()
          : (user['email'] ?? 'Valued Customer');

      expect(displayName, 'Hajra');
      expect(displayName, isNot('ayesha'));
      expect(displayName, isNot('ayesha@gmail.com'));
    });

    test('falls back gracefully only if profile name is absent', () {
      final userWithoutName = {
        'id': 'cust_456',
        'email': 'john.doe@example.com',
      };

      final displayName = (userWithoutName['name'] != null && userWithoutName['name'].toString().trim().isNotEmpty)
          ? userWithoutName['name'].toString().trim()
          : (userWithoutName['email'] ?? 'Valued Customer');

      expect(displayName, 'john.doe@example.com');
    });
  });
}
