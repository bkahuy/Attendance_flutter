import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/student_repository.dart';
import '../../widgets/date_picker_row.dart';
import 'checkin_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _repo = StudentRepository();
  DateTime _date = DateTime.now();
  List<dynamic> _items = [];
  bool _loading = false;
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _repo.schedule(DateFormat('yyyy-MM-dd').format(_date));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _scanQr() {
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => const _QrScanPage()))
        .then((v) {
      if (v is Map<String, dynamic>) {
        final id = v['id'] as int?;
        if (id != null) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => CheckInScreen(sessionId: id)));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Sinh viên')),
        floatingActionButton: FloatingActionButton(
            onPressed: _scanQr, child: const Icon(Icons.qr_code_scanner)),
        body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              DatePickerRow(
                  date: _date,
                  onChanged: (d) {
                    setState(() => _date = d);
                    _load();
                  }),
              const SizedBox(height: 8),
              Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final it = _items[i] as Map<String, dynamic>;
                            final course =
                                (it['course'] as Map?)?['name'] ?? 'Môn học';
                            final room = it['room'] ?? '';
                            return Card(
                                child: ListTile(
                                    title: Text(course),
                                    subtitle:
                                        Text('Phòng: $room | Lớp #${it['id']}'),
                                    trailing: OutlinedButton(
                                        child: const Text('Điểm danh (QR)'),
                                        onPressed: _scanQr)));
                          }))
            ])));
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();
  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Quét QR')),
        body: MobileScanner(onDetect: (cap) {
          if (_done) return;
          final code =
              cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue : null;
          if (code == null) return;
          final uri = Uri.tryParse(code);
          if (uri != null &&
              uri.scheme == 'attendance' &&
              uri.host == 'session') {
            final id = int.tryParse(uri.queryParameters['id'] ?? '');
            if (id != null) {
              _done = true;
              Navigator.pop(context, {'id': id});
            }
          }
        }));
  }
}
