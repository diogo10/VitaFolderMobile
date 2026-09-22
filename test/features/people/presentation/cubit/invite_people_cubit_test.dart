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
          subject: any(named: 'subject'),
          inviteCode: any(named: 'inviteCode'),
          familyName: any(named: 'familyName'),
        ),
      ).thenThrow(result);
    } else {
      when(
        () => functions.sendEmail(
          to: any(named: 'to'),
          subject: any(named: 'subject'),
          inviteCode: any(named: 'inviteCode'),
          familyName: any(named: 'familyName'),
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
      subject: 'Join us',
    ),
    expect: () => [isA<InvitePeopleLoading>(), isA<InvitePeopleSuccess>()],
    verify: (_) {
      verify(
        () => functions.sendEmail(
          to: 'ana@example.com',
          subject: 'Join us',
          inviteCode: null,
          familyName: null,
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
      subject: 'Join us',
      inviteCode: 'ABC123',
      familyName: 'Fam',
    ),
    expect: () => [isA<InvitePeopleLoading>(), isA<InvitePeopleSuccess>()],
    verify: (_) {
      verify(
        () => functions.sendEmail(
          to: 'ana@example.com',
          subject: 'Join us',
          inviteCode: 'ABC123',
          familyName: 'Fam',
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
      subject: 'Join us',
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
      subject: 'Join us',
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
