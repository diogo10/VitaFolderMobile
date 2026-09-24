import 'package:get_it/get_it.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class AccountServiceLocator {
  AccountServiceLocator(this.sl);
  final GetIt sl;

  void init() {
    // The account tab cubit stays a shared lazy singleton (see createRouter
    // factory contract). One-shot cubits (ManageProfileCubit,
    // NotificationSettingsCubit) are built fresh per visit by the route's
    // default factory and never registered here.
    sl.registerLazySingleton<AccountCubit>(
      () => AccountCubit(
        authService: sl<AuthService>(instanceName: 'authService'),
        peopleRepository: sl<PeopleRepository>(
          instanceName: 'peopleRepositoryImpl',
        ),
      ),
      instanceName: 'accountCubit',
    );
  }
}
