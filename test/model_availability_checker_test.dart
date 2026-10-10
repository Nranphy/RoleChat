import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rolechat/services/model_availability_checker.dart';

void main() {
  test(
    'selected address, key and model are sent in an isolated small request',
    () async {
      for (final root in ['https://example.test', 'https://example.test/v1/']) {
        var calls = 0;
        final checker = ModelAvailabilityChecker(
          clientFactory: () => MockClient((request) async {
            calls++;
            expect(
              request.url.toString(),
              'https://example.test/v1/chat/completions',
            );
            expect(request.headers['Authorization'], 'Bearer test-key');
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['model'], 'test-model');
            expect(body['max_completion_tokens'], 16);
            expect(body['messages'], [
              {'role': 'user', 'content': 'Reply only: OK'},
            ]);
            return http.Response(
              jsonEncode({
                'id': 'test',
                'object': 'chat.completion',
                'created': 1,
                'model': 'test-model',
                'choices': [
                  {
                    'index': 0,
                    'message': {'role': 'assistant', 'content': 'OK'},
                    'finish_reason': 'stop',
                  },
                ],
                'usage': {
                  'prompt_tokens': 5,
                  'completion_tokens': 1,
                  'total_tokens': 6,
                },
              }),
              200,
            );
          }),
        );
        final result = await checker.check(
          address: root,
          apiKey: 'test-key',
          model: ' test-model ',
        );
        expect(result.success, isTrue);
        expect(calls, 1);
      }
    },
  );

  test(
    'HTTP failure preserves specific reason without exposing the key or retrying',
    () async {
      var calls = 0;
      final checker = ModelAvailabilityChecker(
        clientFactory: () => MockClient((request) async {
          calls++;
          return http.Response(
            jsonEncode({
              'error': {
                'message': 'Invalid API key: test-key',
                'type': 'authentication_error',
              },
            }),
            401,
          );
        }),
      );
      final result = await checker.check(
        address: 'https://example.test/v1',
        apiKey: 'test-key',
        model: 'missing',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('401'));
      expect(result.message, contains('Invalid API key'));
      expect(result.message, isNot(contains('test-key')));
      expect(calls, 1);
    },
  );

  test(
    'invalid input avoids requests and network failures explain browser limitations',
    () async {
      var calls = 0;
      final checker = ModelAvailabilityChecker(
        clientFactory: () => MockClient((request) async {
          calls++;
          throw http.ClientException('Failed to fetch');
        }),
      );
      expect(
        (await checker.check(address: 'bad', apiKey: '', model: 'x')).success,
        isFalse,
      );
      expect(
        (await checker.check(
          address: 'https://example.test',
          apiKey: '',
          model: '',
        )).success,
        isFalse,
      );
      expect(calls, 0);
      final result = await checker.check(
        address: 'https://example.test',
        apiKey: '',
        model: 'x',
      );
      expect(result.message, contains('CORS'));
      expect(calls, 1);
    },
  );
}
