import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../utils/config.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import 'create_session_sheet.dart';

class TeacherHome extends StatefulWidget {
  final AppUser user;
  const TeacherHome({super.key, required this.user});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final _dio = ApiClient().dio;

  List<Map<String, dynamic>> schedule = [];
  bool loading = true;
  String? err;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final res = await _dio.get(
        AppConfig.teacherSchedulePath,
        queryParameters: {
          'date': _selectedDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final List data = res.data as List;
      schedule = data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      err = 'Lỗi tải lịch: ${e.response?.statusCode ?? e.type.name}';
    } catch (e) {
      err = 'Lỗi: $e';
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate,
    );
    if (d == null) return;
    setState(() => _selectedDate = d);
    await _load();
  }

  Future<void> _quickCreateFromFirst() async {
    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chưa có lớp để tạo phiên')));
      return;
    }
    final item = schedule.first;
    await _openCreateSheetFor(item);
  }

  Future<void> _openCreateSheetFor(Map<String, dynamic> item) async {
    final csId = (item['class_section_id'] as num?)?.toInt();
    if (csId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Thiếu class_section_id')));
      return;
    }
    final label =
        '${item['course_name'] ?? 'Môn'} - ${item['room'] ?? ''} (${item['start_time'] ?? ''}-${item['end_time'] ?? ''})';

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateSessionSheet(
        classSectionId: csId,
        courseLabel: label,
      ),
    );

    if (!mounted) return;
    if (result != null) {
      final token = result['qr']?['token'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(token == null
              ? 'Đã tạo phiên điểm danh'
              : 'Đã tạo phiên — QR token: $token')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh hôm nay'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (err != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(err!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // 🔹 Thanh thao tác
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _quickCreateFromFirst,
                        icon: const Icon(Icons.play_circle),
                        label: const Text('Tạo phiên nhanh (lớp đầu)'),
                      ),
                    ],
                  ),
                ),

                // 🔹 Danh sách lớp trong ngày
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: schedule.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final s = schedule[i];
                      final title = '${s['course_name'] ?? 'Môn'}';
                      final subtitle =
                          'Phòng: ${s['room'] ?? '-'} • ${s['start_time'] ?? ''} - ${s['end_time'] ?? ''}';
                      final teacher = s['teacher_name'] ?? '';

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.class_),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$subtitle${teacher.isNotEmpty ? ' • GV: $teacher' : ''}',
                          ),
                          trailing: FilledButton(
                            onPressed: () => _openCreateSheetFor(s),
                            child: const Text('Mở điểm danh'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
