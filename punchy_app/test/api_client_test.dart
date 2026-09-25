import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:punchy_app/core/api/api_client.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);
  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'token': 'test-token'}));

  test('ApiClient adds auth headers and decodes JSON', () async {
    late http.BaseRequest request;
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      tokenStore: const SharedPreferencesTokenStore(),
      client: _FakeClient((incoming) async {
        request = incoming;
        return http.Response('{"ok":true}', 200);
      }),
    );

    final result = await client.get('/health');
    expect(result, {'ok': true});
    expect(request.headers['authorization'], 'Bearer test-token');
    expect(request.url.toString(), 'https://api.example.test/health');
  });

  test('ApiClient converts API failures into typed ApiException', () async {
    final client = ApiClient(
      tokenStore: const SharedPreferencesTokenStore(),
      client: _FakeClient(
        (_) async => http.Response('{"error":"Denied"}', 403),
      ),
    );

    await expectLater(
      client.get('/private'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
    );
  });

  test(
    'coalesces identical mutations until the first request completes',
    () async {
      var requests = 0;
      final completer = Completer<http.Response>();
      final client = ApiClient(
        baseUrl: 'https://api.example.test',
        tokenStore: const SharedPreferencesTokenStore(),
        client: _FakeClient((_) {
          requests++;
          return completer.future;
        }),
      );

      final first = client.post('/customer/cards/join', {'cardId': 'card-1'});
      final second = client.post('/customer/cards/join', {'cardId': 'card-1'});
      await Future<void>.delayed(Duration.zero);
      expect(requests, 1);

      completer.complete(http.Response('{"ok":true}', 200));
      await Future.wait([first, second]);

      await client.post('/customer/cards/join', {'cardId': 'card-1'});
      expect(requests, 2);
    },
  );
}
