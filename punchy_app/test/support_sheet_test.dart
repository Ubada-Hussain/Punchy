import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:punchy_app/core/api/api_client.dart';
import 'package:punchy_app/features/system_states/support_sheet.dart';

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> delete() async {}

  @override
  Future<String?> read() async => 'test-token';

  @override
  Future<void> write(String token) async {}
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response.body)),
      response.statusCode,
      request: request,
    );
  }
}

ApiClient _api(
  Future<http.Response> Function(http.BaseRequest request) handler,
) => ApiClient(
  baseUrl: 'https://api.example.test',
  tokenStore: _MemoryTokenStore(),
  client: _FakeClient(handler),
);

Future<void> _openComplaint(WidgetTester tester, ApiClient api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SupportSheet(apiClient: api)),
    ),
  );
  await tester.tap(find.text('Submit Complaint'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('submits the trimmed current subject and issue text', (
    tester,
  ) async {
    late Map<String, dynamic> requestBody;
    var requests = 0;
    final api = _api((request) async {
      requests++;
      requestBody = jsonDecode((request as http.Request).body);
      return http.Response('{"id":"ticket-1"}', 201);
    });
    await _openComplaint(tester, api);

    await tester.enterText(
      find.byKey(const Key('complaint_subject_input')),
      '  A  ',
    );
    await tester.enterText(
      find.byKey(const Key('complaint_issue_input')),
      '  B  ',
    );
    await tester.tap(find.byKey(const Key('complaint_send_button')));
    await tester.pumpAndSettle();

    expect(requests, 1);
    expect(requestBody['subject'], 'A');
    expect(requestBody['body'], 'B');
    expect(requestBody['clientRequestId'], isNotEmpty);
    expect(find.text('Complaint submitted successfully.'), findsOneWidget);
    expect(find.text('Subject'), findsNothing);
  });

  testWidgets('rapid Send taps start only one request and show progress', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var requests = 0;
    final api = _api((_) {
      requests++;
      return response.future;
    });
    await _openComplaint(tester, api);
    await tester.enterText(
      find.byKey(const Key('complaint_subject_input')),
      'Subject',
    );
    await tester.enterText(
      find.byKey(const Key('complaint_issue_input')),
      'Issue',
    );

    final send = find.byKey(const Key('complaint_send_button'));
    await tester.tap(send);
    await tester.tap(send);
    await tester.pump();

    expect(requests, 1);
    expect(find.text('Sending…'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(send).onPressed, isNull);

    response.complete(http.Response('{"id":"ticket-1"}', 201));
    await tester.pumpAndSettle();
    expect(requests, 1);
  });

  testWidgets('shows field-specific errors for empty trimmed values', (
    tester,
  ) async {
    final api = _api((_) async => http.Response('{}', 201));
    await _openComplaint(tester, api);

    await tester.enterText(
      find.byKey(const Key('complaint_issue_input')),
      'Issue',
    );
    await tester.tap(find.byKey(const Key('complaint_send_button')));
    await tester.pump();
    expect(find.text('Please enter a subject.'), findsOneWidget);
    expect(find.text('Please describe your issue.'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('complaint_subject_input')),
      'Subject',
    );
    await tester.enterText(
      find.byKey(const Key('complaint_issue_input')),
      '   ',
    );
    await tester.tap(find.byKey(const Key('complaint_send_button')));
    await tester.pump();
    expect(find.text('Please enter a subject.'), findsNothing);
    expect(find.text('Please describe your issue.'), findsOneWidget);
  });

  testWidgets('shows an API error and allows a successful retry', (
    tester,
  ) async {
    var requests = 0;
    final api = _api((_) async {
      requests++;
      if (requests == 1) {
        return http.Response(
          '{"error":"Service temporarily unavailable."}',
          503,
        );
      }
      return http.Response('{"id":"ticket-1"}', 201);
    });
    await _openComplaint(tester, api);
    await tester.enterText(
      find.byKey(const Key('complaint_subject_input')),
      'Subject',
    );
    await tester.enterText(
      find.byKey(const Key('complaint_issue_input')),
      'Issue',
    );

    final send = find.byKey(const Key('complaint_send_button'));
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('Service temporarily unavailable.'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(send).onPressed, isNotNull);

    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Complaint submitted successfully.'), findsOneWidget);
  });
}
