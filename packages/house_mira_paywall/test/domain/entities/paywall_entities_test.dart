import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_paywall/domain/entities/paywall_data.dart';
import 'package:house_mira_paywall/domain/entities/paywall_feature_entity.dart';
import 'package:house_mira_paywall/domain/entities/paywall_plan_entity.dart';

void main() {
  group('PaywallPlanEntity', () {
    const annual = PaywallPlanEntity(
      id: 'annual',
      monthlyPriceLabel: r'$4.16',
      annualTotalLabel: r'$49.99',
      savePercent: 40,
    );

    test('isAnnual distinguishes annual from monthly', () {
      expect(annual.isAnnual, isTrue);
      expect(
        const PaywallPlanEntity(
          id: 'monthly',
          monthlyPriceLabel: r'$7.99',
        ).isAnnual,
        isFalse,
      );
    });

    test('copyWith replaces every field', () {
      final copied = annual.copyWith(
        id: 'monthly',
        monthlyPriceLabel: r'$7.99',
        annualTotalLabel: 'none',
        savePercent: 10,
      );

      expect(copied.id, 'monthly');
      expect(copied.monthlyPriceLabel, r'$7.99');
      expect(copied.annualTotalLabel, 'none');
      expect(copied.savePercent, 10);
    });

    test('copyWith keeps fields when no overrides given', () {
      expect(annual.copyWith(), annual);
    });

    test('from parses full and minimal maps', () {
      expect(
        PaywallPlanEntity.from({
          'id': 'annual',
          'monthlyPriceLabel': r'$4.16',
          'annualTotalLabel': r'$49.99',
          'savePercent': 40,
        }),
        annual,
      );
      expect(
        PaywallPlanEntity.from({
          'id': 'monthly',
          'monthlyPriceLabel': r'$7.99',
        }),
        const PaywallPlanEntity(id: 'monthly', monthlyPriceLabel: r'$7.99'),
      );
    });

    test('from ignores non-string annualTotalLabel', () {
      final plan = PaywallPlanEntity.from({
        'id': 'annual',
        'monthlyPriceLabel': r'$4.16',
        'annualTotalLabel': 4999,
      });

      expect(plan?.annualTotalLabel, isNull);
    });

    test('from ignores non-int savePercent', () {
      final plan = PaywallPlanEntity.from({
        'id': 'annual',
        'monthlyPriceLabel': r'$4.16',
        'savePercent': '40',
      });

      expect(plan?.savePercent, isNull);
    });

    test('from returns null on bad input', () {
      expect(PaywallPlanEntity.from(null), isNull);
      expect(PaywallPlanEntity.from('annual'), isNull);
      expect(PaywallPlanEntity.from(<String>[]), isNull);
      expect(PaywallPlanEntity.from({'monthlyPriceLabel': r'$4.16'}), isNull);
      expect(PaywallPlanEntity.from({'id': 'annual'}), isNull);
      expect(
        PaywallPlanEntity.from({'id': 7, 'monthlyPriceLabel': r'$4.16'}),
        isNull,
      );
      expect(
        PaywallPlanEntity.from({'id': 'annual', 'monthlyPriceLabel': 4}),
        isNull,
      );
    });

    test('equality distinguishes fields and types', () {
      expect(annual, annual);
      expect(
        annual,
        const PaywallPlanEntity(
          id: 'annual',
          monthlyPriceLabel: r'$4.16',
          annualTotalLabel: r'$49.99',
          savePercent: 40,
        ),
      );
      expect(
        annual.hashCode,
        const PaywallPlanEntity(
          id: 'annual',
          monthlyPriceLabel: r'$4.16',
          annualTotalLabel: r'$49.99',
          savePercent: 40,
        ).hashCode,
      );
      expect(
        annual ==
            const PaywallPlanEntity(id: 'other', monthlyPriceLabel: r'$4.16'),
        isFalse,
      );
      expect(
        annual ==
            const PaywallPlanEntity(
              id: 'annual',
              monthlyPriceLabel: r'$0.00',
              annualTotalLabel: r'$49.99',
              savePercent: 40,
            ),
        isFalse,
      );
      expect(
        annual ==
            const PaywallPlanEntity(
              id: 'annual',
              monthlyPriceLabel: r'$4.16',
              savePercent: 40,
            ),
        isFalse,
      );
      expect(
        annual ==
            const PaywallPlanEntity(
              id: 'annual',
              monthlyPriceLabel: r'$4.16',
              annualTotalLabel: r'$49.99',
            ),
        isFalse,
      );
      expect(annual == Object(), isFalse);
    });
  });

  group('PaywallFeatureEntity', () {
    test('from parses valid maps and rejects bad input', () {
      expect(
        PaywallFeatureEntity.from({'id': 'sync'}),
        const PaywallFeatureEntity(id: 'sync'),
      );
      expect(PaywallFeatureEntity.from(null), isNull);
      expect(PaywallFeatureEntity.from('sync'), isNull);
      expect(PaywallFeatureEntity.from(<String, dynamic>{}), isNull);
      expect(PaywallFeatureEntity.from({'id': 7}), isNull);
    });

    test('copyWith replaces and keeps the id', () {
      const feature = PaywallFeatureEntity(id: 'sync');
      expect(
        feature.copyWith(id: 'sorting'),
        const PaywallFeatureEntity(id: 'sorting'),
      );
      expect(feature.copyWith(), feature);
    });

    test('equality and hashCode', () {
      const feature = PaywallFeatureEntity(id: 'sync');
      expect(feature, feature);
      expect(feature, const PaywallFeatureEntity(id: 'sync'));
      expect(feature.hashCode, const PaywallFeatureEntity(id: 'sync').hashCode);
      expect(feature == const PaywallFeatureEntity(id: 'other'), isFalse);
      expect(feature == Object(), isFalse);
    });
  });

  group('PaywallData', () {
    const data = PaywallData(
      plans: [
        PaywallPlanEntity(id: 'annual', monthlyPriceLabel: r'$4.16'),
      ],
      features: [PaywallFeatureEntity(id: 'sync')],
    );

    test('copyWith replaces lists', () {
      final copied = data.copyWith(
        plans: const [
          PaywallPlanEntity(id: 'monthly', monthlyPriceLabel: r'$7.99'),
        ],
        features: const [PaywallFeatureEntity(id: 'sorting')],
      );

      expect(copied.plans.single.id, 'monthly');
      expect(copied.features.single.id, 'sorting');
      expect(data.copyWith(), data);
    });

    test('equality compares list contents', () {
      expect(data, data);
      expect(data, data.copyWith());
      expect(data.hashCode, data.copyWith().hashCode);
      expect(
        data ==
            data.copyWith(
              plans: const [
                PaywallPlanEntity(id: 'annual', monthlyPriceLabel: r'$4.16'),
                PaywallPlanEntity(id: 'monthly', monthlyPriceLabel: r'$7.99'),
              ],
            ),
        isFalse,
      );
      expect(
        data ==
            data.copyWith(
              features: const [PaywallFeatureEntity(id: 'other')],
            ),
        isFalse,
      );
      expect(
        data ==
            data.copyWith(
              features: const [
                PaywallFeatureEntity(id: 'sync'),
                PaywallFeatureEntity(id: 'sorting'),
              ],
            ),
        isFalse,
      );
      expect(data == Object(), isFalse);
    });
  });
}
