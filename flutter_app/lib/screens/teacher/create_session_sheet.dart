import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';

class CreateSessionSheet extends StatefulWidget {
  /// Bắt buộc: id lớp học phần mà GV muốn mở điểm danh
  final int classSectionId;
  /// Hiển thị tên môn/lớp cho dễ nhìn (tuỳ ý)
  final String? courseLabel;

  const CreateSessionSheet({
    super.key,
    required this.classSectionId,
    this.courseLabel,
  });

  @override
  State<CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<CreateSessionSheet> {
  final _pwd = TextEditingController();
  DateTime _start = DateTime.now().add(const Duration(minutes: 1));
  DateTime _end   = DateTime.now().add(const Duration(minutes: 91));

  bool _camera = true;
  bool _gps = false;
  bool _submitting = false;

  @override
  void dispose() {
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _start,
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() => _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
    if (_end.isBefore(_start)) {
      setState(() => _end = _start.add(const Duration(minutes: 90)));
    }
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _end,
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_end));
    if (t == null) return;
    final newEnd = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    if (newEnd.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu')));
      return;
    }
    setState(() => _end = newEnd);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final res = await AttendanceService().createSession(
        classSectionId: widget.classSectionId,
        startAt: _start,
        endAt: _end,
        camera: _camera,
        gps: _gps,
        password: _pwd.text.isEmpty ? null : _pwd.text.trim(),
      );
      if (!mounted) return;

      // Trả kết quả về caller (TeacherHome)
      Navigator.of(context).pop(res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tạo phiên thất bại: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            Text(widget.courseLabel == null ? 'Tạo phiên điểm danh' : 'Tạo phiên - ${widget.courseLabel!}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bắt đầu'),
              subtitle: Text(fmt.format(_start)),
              trailing: IconButton(icon: const Icon(Icons.schedule), onPressed: _pickStart),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kết thúc'),
              subtitle: Text(fmt.format(_end)),
              trailing: IconButton(icon: const Icon(Icons.timer_off), onPressed: _pickEnd),
            ),

            SwitchListTile(
              value: _camera,
              onChanged: (v) => setState(() => _camera = v),
              title: const Text('Bắt buộc chụp ảnh'),
            ),
            SwitchListTile(
              value: _gps,
              onChanged: (v) => setState(() => _gps = v),
              title: const Text('Bật kiểm tra GPS'),
            ),
            TextField(
              controller: _pwd,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu (nếu muốn)',
                hintText: 'Ví dụ: 1234',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ) : const Icon(Icons.play_circle),
                label: Text(_submitting ? 'Đang tạo...' : 'Tạo phiên'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
