import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/paywall/data/repository/paywall_repository_impl.dart';
import 'package:house_mira/features/paywall/domain/entities/paywall_data.dart';
import 'package:house_mira/features/paywall/domain/repository/paywall_repository.dart';
import 'package:house_mira/features/paywall/domain/usecase/get_paywall_data_usecase.dart';
import 'package:house_mira/features/paywall/domain/usecase/restore_purchases_usecase.dart';
import 'package:house_mira/features/paywall/domain/usecase/start_trial_usecase.dart';

class _FakePaywallRepository implements PaywallRepository {
  String? lastPlanId;
  var fail = false;

  @override
  Future<Either<Exception, PaywallData>> getPaywallData() async {
    if (fail) return Left(Exception('offline'));
    return const Right(PaywallRepositoryImpl.mockedData);
  }

  @override
  Future<Either<Exception, Unit>> startTrial({required String planId}) async {
    lastPlanId = planId;
    if (fail) return Left(Exception('offline'));
    return const Right(unit);
  }

  @override
  Future<Either<Exception, Unit>> restorePurchases() async {
    if (fail) return Left(Exception('offline'));
    return const Right(unit);
  }
}

void main() {
  late _FakePaywallRepository repository;

  setUp(() {
    repository = _FakePaywallRepository();
  });

  group('GetPaywallDataUsecase', () {
    test('forwards the catalog on success', () async {
      final usecase = GetPaywallDataUsecase(repository: repository);

      final result = await usecase();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (data) => expect(data.plans, hasLength(2)),
      );
    });

    test('forwards repository failures', () async {
      repository.fail = true;
      final usecase = GetPaywallDataUsecase(repository: repository);

      final result = await usecase();

      expect(result.isLeft(), isTrue);
    });
  });

  group('StartTrialUsecase', () {
    test('passes the plan id through on success', () async {
      final usecase = StartTrialUsecase(repository: repository);

      final result = await usecase(planId: 'annual');

      expect(result.isRight(), isTrue);
      expect(repository.lastPlanId, 'annual');
    });

    test('forwards repository failures', () async {
      repository.fail = true;
      final usecase = StartTrialUsecase(repository: repository);

      final result = await usecase(planId: 'annual');

      expect(result.isLeft(), isTrue);
    });
  });

  group('RestorePurchasesUsecase', () {
    test('succeeds through the repository', () async {
      final usecase = RestorePurchasesUsecase(repository: repository);

      final result = await usecase();

      expect(result, const Right<Exception, Unit>(unit));
    });

    test('forwards repository failures', () async {
      repository.fail = true;
      final usecase = RestorePurchasesUsecase(repository: repository);

      final result = await usecase();

      expect(result.isLeft(), isTrue);
    });
  });
}
