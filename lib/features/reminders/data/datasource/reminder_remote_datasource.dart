import 'package:dio/dio.dart';
import 'package:vita_folder_mobile/core/errors/failure.dart';
import 'package:vita_folder_mobile/core/network/dio_client.dart';

Dio http = DioClient.instance();

class ReminderRemoteDatasource {
  Future<List<dynamic>> getReminders() async {
    try {
      final Response<dynamic> response = await http.get('/reminders');
      return response.data;
    } on DioException catch (e) {
      throw Failure(message: e.message ?? 'Dio error occurred');
    } catch (e) {
      throw Exception();
    }
  }
}
