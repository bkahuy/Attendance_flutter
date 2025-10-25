import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'student_checkin_page.dart';
import 'qr_scan_page.dart'; // nhớ import trang quét QR của bạn

class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  // Dữ liệu mẫu — sau này sẽ lấy từ API
  final List<Map<String, dynamic>> _sessions = [
    {'date': '2025-10-13', 'status': 'present'},
    {'date': '2025-10-17', 'status': 'pending'},
    {'date': '2025-10-21', 'status': 'future'},
  ];

  @override
  Widget build(BuildContext context) {
    final courseName = widget.course['course_name'] ?? 'Tên môn học';
    final className = widget.course['class_name'] ?? 'Tên lớp';
    final courseCode = widget.course['course_code'] ?? 'Mã môn';

    // Đếm số buổi đã điểm danh
    final attendedCount = _sessions.where((s) => s['status'] == 'present' || s['status'] == 'late').length;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('Chi tiết môn học', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Thông tin môn học
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$courseCode ${courseName.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lớp: $className',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const Divider(height: 32),
                    // Danh sách buổi học
                    ..._sessions.map((s) => _buildSessionRow(s)).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Thống kê
            Text('Số buổi đã điểm danh: $attendedCount/${_sessions.length}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tổng số buổi: ${_sessions.length}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Tạo dòng hiển thị buổi học
  Widget _buildSessionRow(Map<String, dynamic> session) {
    final date = DateTime.parse(session['date']);
    final formattedDate = DateFormat("EEEE - dd/MM/yy", "vi_VN").format(date);
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final sessionDay = DateUtils.dateOnly(date);

    final status = session['status'];
    Widget statusWidget;

    // Nếu đã có trạng thái cụ thể
    switch (status) {
      case 'present':
        statusWidget = const Text(
          '✅ Có mặt',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        );
        break;

      case 'late':
        statusWidget = const Text(
          '⚠️ Muộn',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        );
        break;

      case 'absent':
        statusWidget = const Text(
          '❌ Vắng',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        );
        break;

      default:
      // Nếu chưa có trạng thái
        if (sessionDay.isAfter(today)) {
          // 🔹 Ngày tương lai → Đang chờ
          statusWidget = const Text(
            '? Đang chờ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          );
        } else if (sessionDay.isBefore(today)) {
          // 🔹 Ngày đã qua (hôm qua hoặc cũ hơn) → Không cho điểm danh
          statusWidget = const Text(
            '❌ Vắng (Quá hạn)',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          );
        } else {
          // 🔹 CHÍNH LÀ HÔM NAY (sessionDay == today) → Cho phép điểm danh
          statusWidget = GestureDetector(
            onTap: () async {
              // B1: Chụp ảnh khuôn mặt
              final picker = ImagePicker();
              final photo = await picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 1280,
                imageQuality: 85,
                preferredCameraDevice: CameraDevice.front,
              );
              // Nếu người dùng hủy chụp ảnh, dừng lại
              if (photo == null) return;
              // B2: Xác nhận điểm danh (Chuyển sang StudentCheckinPage)
              if (!mounted) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentCheckinPage(
                    session: {
                      ...session, // Lấy dữ liệu session gốc
                      'photo_path': photo.path, // Thêm đường dẫn ảnh đã chụp
                    },
                  ),
                ),
              );
              // B3: Cập nhật trạng thái (Logic này giữ nguyên)
              if (result != null && result['checkedIn'] == true) {
                setState(() {
                  final index = _sessions.indexOf(session);
                  if (index != -1) {
                    _sessions[index]['status'] = result['status'];
                  }
                });
              }
            },
            child: const Text(
              'ĐIỂM DANH',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.red,
              ),
            ),
          );
        }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            toBeginningOfSentenceCase(formattedDate) ?? '',
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
          statusWidget,
        ],
      ),
    );
  }

}
