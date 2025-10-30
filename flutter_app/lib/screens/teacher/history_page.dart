import 'package:flutter/material.dart';
import 'detail_page.dart'; // Import màn hình chi tiết để điều hướng

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Đặt index = 1 để icon "Clock" được chọn như trong ảnh
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Thêm logic điều hướng cho các tab khác ở đây (nếu cần)
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng AppBar tùy chỉnh
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử phiên điểm danh',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Thẻ lịch sử 1
            _buildHistoryCard(
              context: context,
              courseName: 'CSE441 Mobile App (9/25)',
              className: '64KTPM3 + 64KTPM-NB',
              location: 'P329 A2',
              time: '8:45',
              courseTitleForDetail: 'Mobile App (64KTPM3+64KTPM-NB)', // Dữ liệu để gửi đi
            ),
            // Thẻ lịch sử 2
            _buildHistoryCard(
              context: context,
              courseName: 'CSE441 Mobile App (9/25)',
              className: '64KTPM4',
              location: 'P321 A2',
              time: '10:35',
              courseTitleForDetail: 'Mobile App (64KTPM4)',
            ),
            // Thẻ lịch sử 3
            _buildHistoryCard(
              context: context,
              courseName: 'CSE441 Mobile App (9/25)',
              className: '64KTPM1',
              location: 'P327 A2',
              time: '7:00',
              courseTitleForDetail: 'Mobile App (64KTPM1)',
            ),
          ],
        ),
      ),
    );
  }

  // Widget trợ giúp để tạo thẻ lịch sử
  Widget _buildHistoryCard({
    required BuildContext context,
    required String courseName,
    required String className,
    required String location,
    required String time,
    required String courseTitleForDetail,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell( // Thêm InkWell để có hiệu ứng gợn sóng khi nhấn
        onTap: () {
          // Xử lý điều hướng khi nhấn vào thẻ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(courseTitle: courseTitleForDetail),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      className,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}