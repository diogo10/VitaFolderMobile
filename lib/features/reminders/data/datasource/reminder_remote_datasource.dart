import 'package:dio/dio.dart';
import 'package:vita_folder_mobile/core/network/dio_client.dart';

Dio http = DioClient.instance();

class ReminderRemoteDatasource {
  Future<List<dynamic>> getReminders() async {
    return List.empty();
  }
}
