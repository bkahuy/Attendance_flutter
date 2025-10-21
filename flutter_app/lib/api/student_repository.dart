import 'package:attendance_app/api/api_client.dart';
import 'package:attendance_app/models/schedule_item.dart';

class StudentRepository {
  final ApiClient _client;

  StudentRepository(this._client);

  Future<List<ScheduleItem>> getScheduleByDate(String date) async {
    final response = await _client.get('/student/schedule?date=$date');
    final List data = response.data['data'];
    return data.map((e) => ScheduleItem.fromJson(e)).toList();
  }
}
