import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira_core/subscriptions/subscription_service.dart';
import 'package:house_mira_paywall/data/repository/paywall_repository_impl.dart';
import 'package:house_mira_paywall/domain/entities/paywall_data.dart';
import 'package:house_mira_paywall/domain/repository/paywall_repository.dart';
import 'package:house_mira_paywall/domain/usecase/get_paywall_data_usecase.dart';
import 'package:house_mira_paywall/domain/usecase/restore_purchases_usecase.dart';
import 'package:house_mira_paywall/domain/usecase/start_trial_usecase.dart';
import 'package:house_mira_paywall/presentation/cubit/paywall_cubit.dart';
import 'package:house_mira_paywall/presentation/cubit/paywall_state.dart';
import 'package:house_mira_paywall/presentation/views/paywall_screen.dart';
import 'package:house_mira_core/generated/app_localizations.dart';

class _FailingRepository implements PaywallRepository {
  var loadCalls = 0;

  @override
  Future<Either<Exception, PaywallData>> getPaywallData() async {
    loadCalls++;
    return Left(Exception('offline'));
  }

  @override
  Future<Either<Exception, Unit>> startTrial({required String planId}) async {
    return Left(Exception('offline'));
  }

  @override
  Future<Either<Exception, Unit>> restorePurchases() async {
    return Left(Exception('offline'));
  }
}

PaywallCubit buildCubit(PaywallRepository repository) => PaywallCubit(
  getPaywallDataUsecase: GetPaywallDataUsecase(repository: repository),
  startTrialUsecase: StartTrialUsecase(repository: repository),
  restorePurchasesUsecase: RestorePurchasesUsecase(repository: repository),
  subscriptionService: SubscriptionService(),
);

Future<void> pumpScreen(WidgetTester tester, PaywallCubit cubit) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<PaywallCubit>.value(
        value: cubit,
        child: const Scaffold(body: PaywallScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PaywallScreen mocked catalog', () {
    testWidgets('renders headline, features, plans and CTA', (tester) async {
      final cubit = buildCubit(PaywallRepositoryImpl());
      addTearDown(cubit.close);
      await pumpScreen(tester, cubit);
      final l = AppLocalizations.of(
        tester.element(find.byType(PaywallScreen)),
      )!;

      expect(find.text(l.paywallLimitReached), findsOneWidget);
      expect(find.text(l.paywallFeatureUnlimitedTitle), findsOneWidget);
      expect(find.text(l.paywallFeatureSortingTitle), findsOneWidget);
      expect(find.text(l.paywallFeatureSyncTitle), findsOneWidget);
      expect(find.text(l.paywallAnnualTitle), findsOneWidget);
      expect(find.text(l.paywallMonthlyTitle), findsOneWidget);
      expect(find.text(l.paywallCtaTrial), findsOneWidget);
      expect(find.text(l.paywallRestore), findsOneWidget);
      expect(find.text(l.paywallSaveBadge(40)), findsOneWidget);
    });

    testWidgets('tapping a plan selects it', (tester) async {
      final cubit = buildCubit(PaywallRepositoryImpl());
      addTearDown(cubit.close);
      await pumpScreen(tester, cubit);
      final l = AppLocalizations.of(
        tester.element(find.byType(PaywallScreen)),
      )!;

      expect(
        (cubit.state as PaywallLoaded).selectedPlanId,
        'annual',
      );
      await tester.ensureVisible(find.text(l.paywallMonthlyTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.paywallMonthlyTitle));
      await tester.pumpAndSettle();

      expect(
        (cubit.state as PaywallLoaded).selectedPlanId,
        'monthly',
      );
    });

    testWidgets('starting the trial shows the placeholder snackbar', (
      tester,
    ) async {
      final cubit = buildCubit(PaywallRepositoryImpl());
      addTearDown(cubit.close);
      await pumpScreen(tester, cubit);
      final l = AppLocalizations.of(
        tester.element(find.byType(PaywallScreen)),
      )!;

      await tester.ensureVisible(find.text(l.paywallCtaTrial));
      await tester.tap(find.text(l.paywallCtaTrial));
      await tester.pumpAndSettle();

      expect(find.text(l.paywallTrialStarted), findsOneWidget);
    });

    testWidgets('restoring purchases shows the placeholder snackbar', (
      tester,
    ) async {
      final cubit = buildCubit(PaywallRepositoryImpl());
      addTearDown(cubit.close);
      await pumpScreen(tester, cubit);
      final l = AppLocalizations.of(
        tester.element(find.byType(PaywallScreen)),
      )!;

      await tester.ensureVisible(find.text(l.paywallRestore));
      await tester.tap(find.text(l.paywallRestore));
      await tester.pumpAndSettle();

      expect(find.text(l.paywallRestoreStarted), findsOneWidget);
    });

    testWidgets('load failure shows the error view with retry', (tester) async {
      final repository = _FailingRepository();
      final cubit = buildCubit(repository);
      addTearDown(cubit.close);
      await pumpScreen(tester, cubit);
      final l = AppLocalizations.of(
        tester.element(find.byType(PaywallScreen)),
      )!;

      // Load fails first: the error view offers a retry.
      expect(find.text(l.paywallLoadFailed), findsOneWidget);
      expect(find.text(l.paywallRetry), findsOneWidget);

      await tester.tap(find.text(l.paywallRetry));
      await tester.pumpAndSettle();

      expect(repository.loadCalls, 2);
      expect(find.text(l.paywallLoadFailed), findsOneWidget);
    });

    testWidgets('close button pops the screen', (tester) async {
      final cubit = buildCubit(PaywallRepositoryImpl());
      addTearDown(cubit.close);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/paywall'),
                child: const Text('open paywall'),
              ),
            ),
          ),
          GoRoute(
            path: '/paywall',
            builder: (context, state) => BlocProvider<PaywallCubit>.value(
              value: cubit,
              child: const Scaffold(body: PaywallScreen()),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open paywall'));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsNothing);
      expect(router.state.uri.path, '/');
    });
  });
}
