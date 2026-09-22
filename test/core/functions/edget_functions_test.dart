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
        subject: 'Invite',
      );

      expect(result, isTrue);
      verify(
        () => functions.invoke(
          'resend-email-v1',
          body: any(
            named: 'body',
            that: isA<Map<String, dynamic>>().having(
              (b) => b['to'],
              'to',
              'a@b.c',
            ),
          ),
        ),
      ).called(1);
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
        await build().sendEmail(to: 'a@b.c', subject: 'Invite'),
        isFalse,
      );
    });

    test('returns false when the response has no data', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => const FunctionResponse(status: 200));

      expect(
        await build().sendEmail(to: 'a@b.c', subject: 'Invite'),
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
        await build().sendEmail(to: 'a@b.c', subject: 'Invite'),
        isFalse,
      );
    });

    test('propagates network failures', () async {
      when(
        () => functions.invoke(any(), body: any(named: 'body')),
      ).thenThrow(Exception('Network error'));

      expect(
        () => build().sendEmail(to: 'a@b.c', subject: 'Invite'),
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
        () => build().sendEmail(to: 'a@b.c', subject: 'Invite'),
        throwsA(isA<FunctionException>()),
      );
    });

    test('embeds the mobile App Link when an invite code is given', () async {
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
        subject: 'Join Fam',
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
      expect(
        captured['html'],
        contains('https://vitafolder.app/invite/ABC123'),
      );
      expect(captured['html'], contains('Fam'));
    });

    test('sends a generic prompt without fabricating a link', () async {
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
        subject: 'Join us',
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
      expect(captured['html'], isNot(contains('vitafolder.app/invite/')));
    });
  });
}
