import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(AccountInitial());

  Future<void> loadAccount() async {
    emit(AccountLoading());
    await Future.delayed(const Duration(milliseconds: 100));
    emit(AccountLoaded());
  }
}
