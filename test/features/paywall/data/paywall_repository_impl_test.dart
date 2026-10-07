import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/paywall/data/repository/paywall_repository_impl.dart';

void main() {
  late PaywallRepositoryImpl repository;

  setUp(() {
    repository = PaywallRepositoryImpl();
  });

  group('PaywallRepositoryImpl mocked catalog', () {
    test('returns the annual and monthly plans with features', () async {
      final result = await repository.getPaywallData();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (data) {
          expect(data.plans.map((plan) => plan.id), ['annual', 'monthly']);
          expect(
            data.features.map((feature) => feature.id),
            ['unlimited', 'sorting', 'sync'],
          );
          final annual = data.plans.first;
          expect(annual.monthlyPriceLabel, r'$4.16');
          expect(annual.annualTotalLabel, r'$49.99');
          expect(annual.savePercent, 40);
        },
      );
    });

    test('startTrial succeeds for a plan id', () async {
      final result = await repository.startTrial(planId: 'annual');

      expect(result.isRight(), isTrue);
    });

    test('startTrial fails for blank plan ids', () async {
      expect((await repository.startTrial(planId: '')).isLeft(), isTrue);
      expect((await repository.startTrial(planId: '   ')).isLeft(), isTrue);
    });

    test('restorePurchases succeeds', () async {
      final result = await repository.restorePurchases();

      expect(result.isRight(), isTrue);
    });
  });
}
