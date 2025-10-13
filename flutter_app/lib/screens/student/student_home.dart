import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../api/api_client.dart';
import '../../utils/config.dart';
import '../../models/user.dart';
import 'qr_scan_page.dart';

class StudentHome extends StatefulWidget {
  final AppUser user;
  const StudentHome({super.key, required this.user});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  List<Map<String, dynamic>> schedule = [];
  bool loading = true;
  String? err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; err = null; });
    try {
      final res = await ApiClient().dio.get(AppConfig.studentSchedulePath, queryParameters: {
        'date': DateTime.now().toIso8601String().substring(0,10),
      });
      final List data = res.data as List;
      schedule = data.cast<Map<String,dynamic>>();
    } on DioException catch (e) {
      err = 'Lỗi tải lịch: ${e.response?.statusCode}';
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (err != null) return Center(child: Text(err!));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrScanPage()));
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Quét QR để điểm danh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: schedule.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final s = schedule[i];
              return Card(
                child: ListTile(
                  title: Text('${s['course_name'] ?? 'Môn'} - ${s['room'] ?? ''}'),
                  subtitle: Text('Giờ: ${s['start_time'] ?? ''} - ${s['end_time'] ?? ''}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
