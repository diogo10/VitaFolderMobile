import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/functions/edget_functions.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:house_mira/features/people/presentation/views/invite_people_screen.dart';
import 'package:house_mira/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'fake-publishable-key-for-tests',
    );
  });

  Widget pumpScreen({String? familyName}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<InvitePeopleCubit>(
          create: (_) => InvitePeopleCubit(edgetFunctions: EdgetFunctions()),
          child: Provider<AuthService>(
            create: (_) => AuthService(),
            child: InvitePeopleScreen(familyName: familyName),
          ),
        ),
      ),
    );
  }

  group('InvitePeopleScreen', () {
    testWidgets('builds without crashing when familyName is null', (
      tester,
    ) async {
      await tester.pumpWidget(pumpScreen());
      await tester.pump();

      expect(find.byType(InvitePeopleScreen), findsOneWidget);
      expect(find.byType(SandPrimaryButton), findsOneWidget);
    });

    testWidgets('shows family name in the description when provided', (
      tester,
    ) async {
      await tester.pumpWidget(pumpScreen(familyName: 'Smith Family'));
      await tester.pump();

      expect(find.textContaining('Smith Family'), findsOneWidget);
    });

    testWidgets('shows hero title, email field and send button', (
      tester,
    ) async {
      await tester.pumpWidget(pumpScreen(familyName: 'Smith Family'));
      await tester.pump();

      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.invitePeopleHeroTitle), findsOneWidget);
      expect(find.text(l.invitePeopleSend), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}
