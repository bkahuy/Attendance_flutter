import 'package:flutter/material.dart';
import '../../api/stats_repository.dart';

class StudentOverviewScreen extends StatefulWidget {
  const StudentOverviewScreen({super.key});
  @override
  State<StudentOverviewScreen> createState() => _StudentOverviewScreenState();
}

class _StudentOverviewScreenState extends State<StudentOverviewScreen> {
  final repo = StatsRepository();
  List<dynamic> items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      items = await repo.studentOverview();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan của tôi')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final it = items[i] as Map<String, dynamic>;
                final total = (it['total_sessions'] ?? 0) as int;
                final attended = (it['attended'] ?? 0) as int;
                return Card(
                    child: ListTile(
                        title: Text(it['course'] ?? ''),
                        subtitle: Text('Term: ${it['term'] ?? ''}'),
                        trailing: Text('$attended/$total')));
              },
            ),
    );
  }
}
