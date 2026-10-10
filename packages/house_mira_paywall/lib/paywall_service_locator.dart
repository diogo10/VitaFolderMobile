import 'package:get_it/get_it.dart';
import 'package:house_mira_paywall/data/repository/paywall_repository_impl.dart';
import 'package:house_mira_paywall/domain/repository/paywall_repository.dart';
import 'package:house_mira_paywall/domain/usecase/get_paywall_data_usecase.dart';
import 'package:house_mira_paywall/domain/usecase/restore_purchases_usecase.dart';
import 'package:house_mira_paywall/domain/usecase/start_trial_usecase.dart';

class PaywallServiceLocator {
  PaywallServiceLocator(this.sl);
  final GetIt sl;

  void init() {
    sl
      ..registerSingleton<PaywallRepository>(
        PaywallRepositoryImpl(),
        instanceName: 'paywallRepositoryImpl',
      )
      ..registerSingleton<GetPaywallDataUsecase>(
        GetPaywallDataUsecase(
          repository: sl(instanceName: 'paywallRepositoryImpl'),
        ),
        instanceName: 'getPaywallDataUsecase',
      )
      ..registerSingleton<StartTrialUsecase>(
        StartTrialUsecase(
          repository: sl(instanceName: 'paywallRepositoryImpl'),
        ),
        instanceName: 'startTrialUsecase',
      )
      ..registerSingleton<RestorePurchasesUsecase>(
        RestorePurchasesUsecase(
          repository: sl(instanceName: 'paywallRepositoryImpl'),
        ),
        instanceName: 'restorePurchasesUsecase',
      );
    // PaywallCubit is built fresh per visit by the route's default
    // factory (see createRouter factory contract) and never registered
    // here.
  }
}
