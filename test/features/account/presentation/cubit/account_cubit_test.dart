import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vita_folder_mobile/core/auth/auth_service.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_state.dart';

class FakeAuthService extends AuthService {
  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  User? get currentUser => null;
}

void main() {
  group('AccountCubit', () {
    test('signIn emits AccountLoaded with valid credentials', () async {
      final cubit = AccountCubit(FakeAuthService());

      await cubit.signIn('user@example.com', 'password123');

      expect(cubit.state, isA<AccountLoaded>());
    });
  });
}
