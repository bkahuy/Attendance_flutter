import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';
import 'qr_screen.dart'; // Đảm bảo import đúng ShowQrPage

class CreateSessionPage extends StatefulWidget {
  final Map<String, dynamic> schedule;
  const CreateSessionPage({super.key, required this.schedule});

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  // Biến state cho form tạo mới
  final _passController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loadingCreate = false;

  // 🔹 Biến state để kiểm tra phiên đã tồn tại
  bool _isCheckingSession = true; // 🔹 Bắt đầu bằng true
  Map<String, dynamic>? _existingSession; // 🔹 Lưu phiên đã có

  @override
  void initState() {
    super.initState();
    // 🔹 Gọi hàm kiểm tra khi trang được mở
    _checkExistingSession();
  }

  // 🔹Kiểm tra phiên đã tồn tại
  Future<void> _checkExistingSession() async {
    try {
      final response = await AttendanceService().getActiveSessionByClass(
        widget.schedule['class_section_id'],
      );

      // Nếu service trả về dữ liệu (tức là tìm thấy phiên)
      if (response != null && response['session'] != null) {
        // Xử lý dữ liệu trả về, giống hệt như logic trong _createSession
        final Map<String, dynamic> session = Map<String, dynamic>.from(response['session']);
        final Map<String, dynamic>? qr = response['qr'] != null ? Map<String, dynamic>.from(response['qr']) : null;

        if (qr != null) {
          session['token'] = qr['token'];
        }

        // Thêm thông tin từ schedule (phòng trường hợp session không có)
        session['course_name'] ??= widget.schedule['course_name'];
        session['room'] ??= widget.schedule['room'];
        session['class_name'] ??= widget.schedule['class_names'];

        if (mounted) {
          setState(() {
            _existingSession = session; // 🔹 Lưu phiên tìm thấy
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi kiểm tra phiên: $e");
      // Không cần làm gì, _existingSession sẽ vẫn là null
      // và form tạo mới sẽ được hiển thị
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSession = false; // 🔹 Dừng kiểm tra
        });
      }
    }
  }

  // (Các hàm _pickStartTime và _pickEndTime giữ nguyên)
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
    // if (picked != null) setState(() => _endTime = picked);
    // 2. Chuyển đổi TimeOfDay sang một số có thể so sánh (ví dụ: tổng số phút)
    final double pickedInMinutes = picked!.hour * 60.0 + picked.minute;
    final double startInMinutes = _startTime!.hour * 60.0 + _startTime!.minute;

    // 3. So sánh
    if (pickedInMinutes < startInMinutes) {
      // Nếu không hợp lệ, hiển thị thông báo lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giờ kết thúc không được nhỏ hơn giờ bắt đầu!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Nếu hợp lệ (lớn hơn hoặc bằng), cập nhật state
      setState(() => _endTime = picked);
    }
  }


  // (Hàm _createSession giữ nguyên, chỉ đổi tên _loading)
  Future<void> _createSession() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu và kết thúc')),
      );
      return;
    }

    setState(() => _loadingCreate = true); // 🔹 Đổi tên biến
    try {
      final now = DateTime.now();
      var startAt = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
      var endAt = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);

      if (endAt.isBefore(startAt)) {
        endAt = endAt.add(const Duration(days: 1));
      }

      final response = await AttendanceService().createSession(
        classSectionId: widget.schedule['class_section_id'],
        startAt: startAt,
        endAt: endAt,
        camera: true,
        qr: true,

        password: _passController.text.isEmpty ? null : _passController.text,
      );

      final Map<String, dynamic> session = Map<String, dynamic>.from(response['session'] ?? {});
      final Map<String, dynamic>? qr = response['qr'] != null ? Map<String, dynamic>.from(response['qr']) : null;

      if (qr != null) {
        session['token'] = qr['token'];
      }

      if (!mounted) return;

      session['start_at'] ??= startAt.toIso8601String();
      session['end_at'] ??= endAt.toIso8601String();
      session['course_name'] ??= widget.schedule['course_name'];
      session['room'] ??= widget.schedule['room'];
      session['class_name'] ??= widget.schedule['class_names'];

      Navigator.pushReplacement( // 🔹 Dùng replacement để không quay lại trang tạo
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
      if (mounted) setState(() => _loadingCreate = false); // 🔹 Đổi tên biến
    }
  }

  // 🔹 HÀM MỚI: Điều hướng đến trang QR đã có
  void _showExistingQr() {
    if (_existingSession == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowQrPage(session: _existingSession!),
      ),
    );
  }

  // 🔹 HÀM MỚI: Helper định dạng thời gian (vì session trả về ISO string)
  String _formatDateTime(String? isoString) {
    if (isoString == null) return '—';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      // Định dạng HH:mm
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Phiên điểm danh'), // 🔹 Đổi title chung
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        // 🔹 Dùng hàm _buildBody để quyết định hiển thị gì
        child: _buildBody(),
      ),
    );
  }

  // 🔹 HÀM MỚI: Quyết định nội dung body
  Widget _buildBody() {
    if (_isCheckingSession) {
      // 1. Trạng thái đang tải
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 16),
            Text('Đang kiểm tra phiên điểm danh...'),
          ],
        ),
      );
    }

    if (_existingSession != null) {
      // 2. Nếu tìm thấy phiên
      return _buildExistingSessionView();
    } else {
      // 3. Nếu không tìm thấy, hiển thị form tạo mới
      return _buildCreateSessionForm();
    }
  }

  // 🔹 HÀM MỚI: Giao diện khi đã có phiên
  Widget _buildExistingSessionView() {
    final s = _existingSession!;
    final course = s['course_name'] ?? '—';
    final room = s['room'] ?? '—';
    final className = s['class_name'] ?? '—';
    // 🔹 Lấy thời gian từ session đã có, không phải từ schedule
    final start = _formatDateTime(s['start_at']);
    final end = _formatDateTime(s['end_at']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Thẻ thông báo
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
                const Text(
                  'Đã có phiên điểm danh đang hoạt động',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(height: 16),
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
                  Expanded(child: Text('Đang hoạt động: $start - $end')),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 🔹 Nút hiển thị lại QR
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showExistingQr, // 🔹 Gọi hàm điều hướng
              label: const Text(
                'Hiển thị lại mã QR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 🔹 Nút để tạo phiên mới (ghi đè?)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // Chỉ cần set _existingSession = null, build() sẽ tự động
                // vẽ lại form tạo mới
                setState(() {
                  _existingSession = null;
                });
              },
              child: const Text(
                '...hoặc tạo một phiên mới (ghi đè phiên cũ)',
                style: TextStyle(color: Colors.deepPurpleAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 HÀM MỚI: Toàn bộ UI cũ của bạn được chuyển vào đây
  Widget _buildCreateSessionForm() {
    // Đây là code gốc trong body: của bạn
    final s = widget.schedule;
    final course = s['course_name'] ?? '—';
    final room = s['room'] ?? '—';
    final start = s['start_time'] ?? '—';
    final end = s['end_time'] ?? '—';
    final className = s['class_names'] ?? '—';

    return SingleChildScrollView(
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
              icon: _loadingCreate // 🔹 Đổi tên biến
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
              onPressed: _loadingCreate ? null : _createSession, // 🔹 Đổi tên biến
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
    );
  }
}