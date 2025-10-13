// lib/pages/student/overview_student.dart
import 'package:flutter/material.dart';
import '../../api/stats_repository.dart';

class StudentOverviewPage extends StatefulWidget {
  const StudentOverviewPage({super.key});

  @override
  State<StudentOverviewPage> createState() => _StudentOverviewPageState();
}

class _StudentOverviewPageState extends State<StudentOverviewPage> {
  final repo = StatsRepository();
  bool loading = true;
  String? err;

  Map<String, dynamic>? data; // <-- Map, không phải List

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; err = null; });
    try {
      data = await repo.studentOverview();  // trả Map
    } catch (e) {
      err = '$e';
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (err != null) return Center(child: Text('Lỗi: $err'));
    if (data == null) return const Center(child: Text('Không có dữ liệu'));

    // Giả định shape JSON:
    // {
    //   "total_sessions": 20,
    //   "present": 15,
    //   "late": 2,
    //   "absent": 3,
    //   "by_class": [
    //     {"class":"64KTPM3","present":5,"late":1,"absent":1},
    //     ...
    //   ]
    // }
    final total = (data!['total_sessions'] ?? 0) as int;
    final present = (data!['present'] ?? 0) as int;
    final late = (data!['late'] ?? 0) as int;
    final absent = (data!['absent'] ?? 0) as int;
    final List byClass = (data!['by_class'] ?? []) as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            _kpi('Tổng số buổi', '$total'),
            _kpi('Có mặt', '$present'),
            _kpi('Muộn', '$late'),
            _kpi('Vắng', '$absent'),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Theo lớp', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...byClass.cast<Map>().map((c) => Card(
          child: ListTile(
            title: Text('${c['class'] ?? 'Lớp'}'),
            subtitle: Text('Có mặt: ${c['present'] ?? 0} • Muộn: ${c['late'] ?? 0} • Vắng: ${c['absent'] ?? 0}'),
          ),
        )),
      ],
    );
  }

  Widget _kpi(String title, String value) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
