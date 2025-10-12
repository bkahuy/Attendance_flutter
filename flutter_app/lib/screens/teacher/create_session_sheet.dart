import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/teacher_repository.dart';
import '../../widgets/primary_button.dart';
import '../../utils/format.dart';
import 'qr_screen.dart';

class CreateSessionSheet extends StatefulWidget {
  final int classSectionId;
  const CreateSessionSheet({super.key, required this.classSectionId});
  @override
  State<CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<CreateSessionSheet> {
  final _repo = TeacherRepository();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 2));
  bool _qr = true;
  final _pwd = TextEditingController();
  bool _loading = false;
  Future<void> _pickStart() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _start,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (d == null) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() => _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _end,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (d == null) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_end));
    if (t == null) return;
    setState(() => _end = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.createSession(
          classSectionId: widget.classSectionId,
          startAt: hms.format(_start),
          endAt: hms.format(_end),
          qr: _qr,
          camera: true,
          password: _pwd.text.isEmpty ? null : _pwd.text);
      if (!mounted) return;
      final session = res['session'] as Map<String, dynamic>;
      final qr = res['qr'] as Map<String, dynamic>?;
      final id = session['id'] as int;
      final token = qr?['token'] as String?;
      final qrText = 'attendance://session?id=$id&token=${token ?? ''}';
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => QrScreen(
                  qrText: qrText, sessionId: id, password: _pwd.text)));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Tạo thất bại: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tạo Buổi Điểm Danh',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Text(
                        'Bắt đầu: ${DateFormat('dd/MM HH:mm').format(_start)}')),
                TextButton(onPressed: _pickStart, child: const Text('Chọn'))
              ]),
              Row(children: [
                Expanded(
                    child: Text(
                        'Kết thúc: ${DateFormat('dd/MM HH:mm').format(_end)}')),
                TextButton(onPressed: _pickEnd, child: const Text('Chọn'))
              ]),
              TextField(
                  controller: _pwd,
                  decoration:
                      const InputDecoration(labelText: 'Password (nếu có)')),
              SwitchListTile(
                  value: _qr,
                  onChanged: (v) => setState(() => _qr = v),
                  title: const Text('Bật QR cho SV quét')),
              const SizedBox(height: 12),
              PrimaryButton(text: 'Tạo', onPressed: _submit, loading: _loading),
              const SizedBox(height: 8),
            ]));
  }
}
