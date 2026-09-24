import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late _MockSupabaseClient supabase;
  late _MockFunctionsClient functions;

  setUp(() {
    supabase = _MockSupabaseClient();
    functions = _MockFunctionsClient();
    when(() => supabase.functions).thenReturn(functions);
  });

  EdgetFunctions build() => EdgetFunctions(supabaseClient: supabase);

  group('EdgetFunctions.sendEmail', () {
    test('returns true when the edge function reports success', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          data: {'success': true},
          status: 200,
        ),
      );

      final result = await build().sendEmail(
        to: 'a@b.c',
        locale: 'en',
        inviterName: 'Ana',
        familyName: 'Smith',
        inviteCode: 'ABC-123',
      );

      expect(result, isTrue);
      verify(
        () => functions.invoke(
          'resend-email-v1',
          body: any(
            named: 'body',
            that: isA<Map<String, dynamic>>()
                .having((b) => b['to'], 'to', 'a@b.c')
                .having((b) => b['locale'], 'locale', 'en')
                .having((b) => b['inviterName'], 'inviterName', 'Ana')
                .having((b) => b['familyName'], 'familyName', 'Smith')
                .having((b) => b['inviteCode'], 'inviteCode', 'ABC-123'),
          ),
        ),
      ).called(1);
    });

    test('omits optional invite fields when not provided', () async {
      Map<String, dynamic>? sentBody;
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer((invocation) async {
        sentBody =
            invocation.namedArguments[const Symbol('body')]
                as Map<String, dynamic>;
        return const FunctionResponse(
          data: {'success': true},
          status: 200,
        );
      });

      await build().sendEmail(to: 'a@b.c', locale: 'pt');

      expect(sentBody?['locale'], 'pt');
      expect(sentBody?.containsKey('inviterName'), isFalse);
      expect(sentBody?.containsKey('familyName'), isFalse);
      expect(sentBody?.containsKey('inviteCode'), isFalse);
    });

    test('returns false when the edge function reports failure', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          data: {'success': false},
          status: 200,
        ),
      );

      expect(
        await build().sendEmail(to: 'a@b.c', locale: 'en'),
        isFalse,
      );
    });

    test('returns false when the response has no data', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => const FunctionResponse(status: 200));

      expect(
        await build().sendEmail(to: 'a@b.c', locale: 'en'),
        isFalse,
      );
    });

    test('returns false when the success flag is missing', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          data: {'other': 'value'},
          status: 200,
        ),
      );

      expect(
        await build().sendEmail(to: 'a@b.c', locale: 'en'),
        isFalse,
      );
    });

    test('propagates network failures', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenThrow(Exception('Network error'));

      expect(
        () => build().sendEmail(to: 'a@b.c', locale: 'en'),
        throwsException,
      );
    });

    test('propagates function relay errors', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenThrow(
        const FunctionException(status: 502, reasonPhrase: 'relay down'),
      );

      expect(
        () => build().sendEmail(to: 'a@b.c', locale: 'en'),
        throwsA(isA<FunctionException>()),
      );
    });

    test('forwards locale and invite data for server rendering', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          data: {'success': true},
          status: 200,
        ),
      );

      final result = await build().sendEmail(
        to: 'a@b.c',
        locale: 'pt',
        inviterName: 'Ana',
        inviteCode: 'ABC123',
        familyName: 'Fam',
      );

      expect(result, isTrue);
      final captured =
          verify(
                () => functions.invoke(
                  'resend-email-v1',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['locale'], 'pt');
      expect(captured['inviterName'], 'Ana');
      expect(captured['inviteCode'], 'ABC123');
      expect(captured['familyName'], 'Fam');
      // Subject and HTML are rendered server-side — never sent by the client.
      expect(captured.containsKey('subject'), isFalse);
      expect(captured.containsKey('html'), isFalse);
    });

    test('sends only to and locale without invite data', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => const FunctionResponse(
          data: {'success': true},
          status: 200,
        ),
      );

      final result = await build().sendEmail(to: 'a@b.c', locale: 'en');

      expect(result, isTrue);
      final captured =
          verify(
                () => functions.invoke(
                  'resend-email-v1',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured, {'to': 'a@b.c', 'locale': 'en'});
    });
  });
}
