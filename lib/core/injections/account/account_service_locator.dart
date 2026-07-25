import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/people/domain/repository/people_repository.dart';

class AccountServiceLocator {
  final GetIt sl;
  AccountServiceLocator(this.sl);

  void init() {
    sl.registerSingleton<AccountCubit>(
      AccountCubit(
        authService: sl<AuthService>(instanceName: 'authService'),
        peopleRepository: sl<PeopleRepository>(instanceName: 'peopleRepositoryImpl'),
      ),
      instanceName: 'accountCubit',
    );
  }
}
