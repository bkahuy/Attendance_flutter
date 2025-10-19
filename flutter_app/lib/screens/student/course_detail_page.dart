import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CourseDetailPage extends StatefulWidget {
  // Trang này nhận dữ liệu của môn học được bấm vào
  final Map<String, dynamic> course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  // Dữ liệu giả lập, sau này bạn sẽ gọi API để lấy dữ liệu thật
  final List<Map<String, dynamic>> _sessions = [
    {'date': '2025-10-13', 'status': 'present'},
    {'date': '2025-10-17', 'status': 'pending'},
    {'date': '2025-10-20', 'status': 'future'},
  ];

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin từ dữ liệu được truyền vào
    final courseName = widget.course['course_name'] ?? 'Tên môn học';
    final className = widget.course['class_name'] ?? 'Tên lớp';
    final courseCode = widget.course['course_code'] ?? 'Mã môn';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('Trang chủ', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Thẻ thông tin chính
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
                    // Danh sách các buổi học
                    ..._sessions.map((session) => _buildSessionRow(session)).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Thống kê điểm danh
            Text('Số buổi đã điểm danh: 1/${_sessions.length}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tổng số buổi: ${_sessions.length}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Widget con để hiển thị một hàng (buổi học)
  Widget _buildSessionRow(Map<String, dynamic> session) {
    final date = DateTime.parse(session['date']);
    final formattedDate = DateFormat("EEEE - dd/MM/yy", "vi_VN").format(date);
    final status = session['status'];

    Widget statusWidget;
    switch (status) {
      case 'present':
        statusWidget = const Text('Có mặt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
        break;
      case 'pending':
        statusWidget = const Text('?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
        break;
      default: // 'future'
        statusWidget = GestureDetector(
          onTap: () {
            // TODO: Mở màn hình quét QR để điểm danh
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