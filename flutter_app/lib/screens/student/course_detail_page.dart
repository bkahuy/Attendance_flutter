import 'package:flutter/material.dart';
import 'qr_scan_page.dart';
import 'package:intl/intl.dart';

class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          _buildCourseDetail(),
          const Center(child: Text("Trang QR (sẽ mở riêng)")),
          const Center(child: Text("Cài đặt (đang phát triển...)")),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF9C8CFC),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          type: BottomNavigationBarType.fixed,
          onTap: (index) async {
            if (index == 1) {
              // Khi nhấn icon QR → mở trang quét riêng biệt
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScanPage()),
              );
            } else {
              setState(() => currentIndex = index);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_2_outlined),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDetail() {
    final course = widget.course;
    return Scaffold(
      appBar: AppBar(
        title: Text(course['course_name'] ?? 'Chi tiết môn học'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course['course_name'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text("Lớp: ${course['class_name'] ?? '--'}",
                style: const TextStyle(fontSize: 16)),
            Text("Phòng học: ${course['room'] ?? '--'}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "Thời gian: ${course['start_time'] ?? '--'} - ${course['end_time'] ?? '--'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScanPage()),
                  );
                },
                icon: const Icon(Icons.qr_code_2_outlined),
                label: const Text("Điểm danh bằng QR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
