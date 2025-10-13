import 'package:flutter/material.dart';
import '../../api/stats_repository.dart';

class SessionStatsScreen extends StatefulWidget {
  final int sessionId;
  const SessionStatsScreen({super.key, required this.sessionId});
  @override
  State<SessionStatsScreen> createState() => _SessionStatsScreenState();
}

class _SessionStatsScreenState extends State<SessionStatsScreen> {
  final repo = StatsRepository();
  Map<String, dynamic>? data;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      data = await repo.sessionStats(widget.sessionId);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = data?['totals'] ?? {};
    final records = (data?['records'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê buổi')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                    'Present: ${totals['present'] ?? 0} | Late: ${totals['late'] ?? 0} | Absent: ${totals['absent'] ?? 0}'),
                const Divider(),
                ...records.map((r) {
                  return ListTile(
                      title: Text(r['student'] ?? ''),
                      subtitle:
                          Text('${r['status']} • ${r['created_at'] ?? ''}'));
                })
              ],
            ),
    );
  }
}
