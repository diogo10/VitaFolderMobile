import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockEdgetFunctions extends Mock implements EdgetFunctions {}

void main() {
  late _MockEdgetFunctions functions;

  setUp(() => functions = _MockEdgetFunctions());

  InvitePeopleCubit build() => InvitePeopleCubit(edgetFunctions: functions);

  Future<void> stubSendEmail(Object? result) {
    if (result is Exception) {
      when(
        () => functions.sendEmail(
          to: any(named: 'to'),
          locale: any(named: 'locale'),
          inviterName: any(named: 'inviterName'),
          familyName: any(named: 'familyName'),
          inviteCode: any(named: 'inviteCode'),
        ),
      ).thenThrow(result);
    } else {
      when(
        () => functions.sendEmail(
          to: any(named: 'to'),
          locale: any(named: 'locale'),
          inviterName: any(named: 'inviterName'),
          familyName: any(named: 'familyName'),
          inviteCode: any(named: 'inviteCode'),
        ),
      ).thenAnswer((_) async => result! as bool);
    }
    return Future.value();
  }

  test('initial state is InvitePeopleInitial', () {
    final cubit = build();
    addTearDown(cubit.close);

    expect(cubit.state, isA<InvitePeopleInitial>());
  });

  blocTest<InvitePeopleCubit, InvitePeopleState>(
    'emits loading then success when the invite is sent',
    build: build,
    setUp: () => stubSendEmail(true),
    act: (cubit) => cubit.sendInvite(
      email: 'ana@example.com',
      relationship: InviteRelationship.spouse,
      locale: 'en',
      inviterName: 'Ana',
      familyName: 'Smith',
      inviteCode: 'ABC-123',
    ),
    expect: () => [isA<InvitePeopleLoading>(), isA<InvitePeopleSuccess>()],
    verify: (_) {
      verify(
        () => functions.sendEmail(
          to: 'ana@example.com',
          locale: 'en',
          inviterName: 'Ana',
          familyName: 'Smith',
          inviteCode: 'ABC-123',
        ),
      ).called(1);
    },
  );

  blocTest<InvitePeopleCubit, InvitePeopleState>(
    'forwards the invite code and family name to the email body',
    build: build,
    setUp: () => stubSendEmail(true),
    act: (cubit) => cubit.sendInvite(
      email: 'ana@example.com',
      relationship: InviteRelationship.spouse,
      locale: 'en',
      familyName: 'Fam',
      inviteCode: 'ABC123',
    ),
    expect: () => [isA<InvitePeopleLoading>(), isA<InvitePeopleSuccess>()],
    verify: (_) {
      verify(
        () => functions.sendEmail(
          to: 'ana@example.com',
          locale: 'en',
          inviterName: null,
          familyName: 'Fam',
          inviteCode: 'ABC123',
        ),
      ).called(1);
    },
  );

  blocTest<InvitePeopleCubit, InvitePeopleState>(
    'emits sendFailed when the edge function reports false',
    build: build,
    setUp: () => stubSendEmail(false),
    act: (cubit) => cubit.sendInvite(
      email: 'ana@example.com',
      relationship: InviteRelationship.child,
      locale: 'pt',
    ),
    expect: () => [
      isA<InvitePeopleLoading>(),
      isA<InvitePeopleError>().having(
        (e) => e.code,
        'code',
        InvitePeopleErrorCode.sendFailed,
      ),
    ],
  );

  blocTest<InvitePeopleCubit, InvitePeopleState>(
    'emits error message when sending throws',
    build: build,
    setUp: () => stubSendEmail(Exception('boom')),
    act: (cubit) => cubit.sendInvite(
      email: 'ana@example.com',
      relationship: InviteRelationship.other,
      locale: 'en',
    ),
    expect: () => [
      isA<InvitePeopleLoading>(),
      isA<InvitePeopleError>().having(
        (e) => e.message,
        'message',
        contains('boom'),
      ),
    ],
  );
}
