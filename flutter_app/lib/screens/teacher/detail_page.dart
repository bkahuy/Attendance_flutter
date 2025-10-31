import 'package:flutter/material.dart';

// Dữ liệu mẫu cho sinh viên
class Student {
  final String id;
  final String name;
  final String status;

  Student(this.id, this.name, this.status);
}

class DetailPage extends StatefulWidget {
  final String courseTitle;

  const DetailPage({super.key, required this.courseTitle, required String sessionId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  // Trạng thái lọc
  String _selectedFilter = 'Tất cả';

  // Dữ liệu sinh viên mẫu (sau này sẽ thay bằng API)
  final List<Student> allStudents = [
    Student('1', 'Bùi Khắc Huy', 'Có mặt'),
    Student('2', 'Trần Tiến Đạt', 'Vắng'),
    Student('3', 'Nguyễn Thành Đồng', 'Muộn'),
    // Thêm sinh viên khác ở đây...
  ];

  // Lấy danh sách sinh viên dựa trên bộ lọc
  List<Student> getFilteredStudents() {
    if (_selectedFilter == 'Tất cả') {
      return allStudents;
    }
    return allStudents.where((s) => s.status == _selectedFilter).toList();
  }

  // Đếm số lượng
  int get presentCount => allStudents.where((s) => s.status == 'Có mặt').length;
  int get absentCount => allStudents.where((s) => s.status == 'Vắng').length;
  int get lateCount => allStudents.where((s) => s.status == 'Muộn').length;

  // Widget cho chip lọc
  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: const Color(0xFFD1C4E9), // Màu tím nhạt khi được chọn
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4527A0) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // Lấy màu cho trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Có mặt':
        return Colors.green;
      case 'Vắng':
        return Colors.red;
      case 'Muộn':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = getFilteredStudents();

    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng cho màn hình này
      appBar: AppBar(
        title: Text(
          widget.courseTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7E57C2), // Màu tím cho AppBar
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Hàng nút "QR CODE" và "Mở lại"
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('QR CODE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh),
                        label: const Text('Mở lại điểm danh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF673AB7), side: const BorderSide(color: Color(0xFF673AB7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Hàng lọc
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFilterChip('Tất cả'),
                    _buildFilterChip('Có mặt'),
                    _buildFilterChip('Vắng'),
                    _buildFilterChip('Muộn'), // Thêm bộ lọc "Muộn"
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bảng dữ liệu sinh viên
          // Dùng DataTable để có bố cục cột ngay ngắn
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 16.0,
                headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                columns: const [
                  DataColumn(label: Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Họ Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredStudents.map((student) {
                  return DataRow(
                    cells: [
                      DataCell(Text(student.id)),
                      DataCell(Text(student.name)),
                      DataCell(
                        Text(
                          student.status,
                          style: TextStyle(
                            color: _getStatusColor(student.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Hộp tổng kết
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Có mặt: $presentCount', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Vắng: $absentCount', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Muộn: $lateCount', style: const TextStyle(fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }
}