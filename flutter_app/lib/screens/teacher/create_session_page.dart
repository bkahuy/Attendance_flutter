import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_screen.dart';

class CreateSessionPage extends StatefulWidget {
  final Map<String, dynamic> schedule;
  const CreateSessionPage({super.key, required this.schedule});

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _passController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loading = false;

  final _attendanceService = AttendanceService();

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.deepPurpleAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.deepPurpleAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _createSession() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu và kết thúc')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final startAt = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
      final endAt = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);

      final session = await AttendanceService().createSession(
        classSectionId: widget.schedule['class_section_id'],
        startAt: startAt,
        endAt: endAt,
        camera: true,
        gps: false,
        password: _passController.text.isEmpty ? null : _passController.text,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ShowQrPage(session: session)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên điểm danh đã được tạo thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo phiên: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    final course = s['course_name'] ?? '—';
    final room = s['room'] ?? '—';
    final start = s['start_time'] ?? '—';
    final end = s['end_time'] ?? '—';
    final className = s['class_names'] ?? '—';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tạo phiên điểm danh'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Thông tin lớp
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.school, color: Colors.deepPurpleAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Môn học: $course',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.class_, color: Colors.deepPurpleAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Lớp: $className')),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.room, color: Colors.deepPurpleAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Phòng: $room')),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.access_time, color: Colors.deepPurpleAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Giờ học: $start - $end')),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Mật khẩu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurpleAccent),
                    labelText: 'Mật khẩu điểm danh (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Giờ bắt đầu - kết thúc
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer, color: Colors.deepPurpleAccent, size: 20),
                        SizedBox(width: 8),
                        Text('Thời gian điểm danh',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickStartTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _startTime == null
                                  ? 'Giờ bắt đầu'
                                  : 'Bắt đầu: ${_startTime!.format(context)}',
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepPurpleAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickEndTime,
                            icon: const Icon(Icons.access_time_filled),
                            label: Text(
                              _endTime == null
                                  ? 'Giờ kết thúc'
                                  : 'Kết thúc: ${_endTime!.format(context)}',
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepPurpleAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.qr_code, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _createSession, // 👈 Gọi hàm tạo phiên
                  label: const Text(
                    'Tạo mã QR và bắt đầu điểm danh',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
