import 'package:fpdart/fpdart.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/features/reminders/data/datasource/reminder_remote_datasource.dart';
import 'package:vita_folder_mobile/features/reminders/data/models/reminder_model.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/repository/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRemoteDatasource reminderRemoteDatasource;
  ReminderRepositoryImpl({required this.reminderRemoteDatasource});

  @override
  Future<Either<Failure, List<ReminderEntity>>> getReminders() async {
    try {
      final reminders = await reminderRemoteDatasource.getReminders();
      final data = reminders.map((r) => ReminderModel.fromMap(r)).toList();
      return Right(data);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      return Left(Failure());
    }
  }
}
