import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:house_mira/features/people/domain/repository/people_repository.dart';

class CreateFamilyUsecase {

  CreateFamilyUsecase({required this.repository});
  final PeopleRepository repository;

  Future<Either<Exception, bool>> call({required String name}) async {
    final inviteCode = _generateInviteCode();
    final result = await repository.createFamily(
      name: name,
      inviteCode: inviteCode,
    );
    if (result.isLeft()) {
      return const Right(false);
    }
    return result;
  }
}

String _generateInviteCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}
