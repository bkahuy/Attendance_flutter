import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../api/api_client.dart';
import '../../utils/config.dart';

class CourseDetailPage extends StatefulWidget {
  // Dữ liệu môn học được truyền từ trang StudentHome
  final Map<String, dynamic> course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Cần thiết lập locale 'vi_VN' để DateFormat
    // có thể hiển thị "Thứ Hai", "Thứ Ba"...
    Intl.defaultLocale = 'vi_VN';
    _loadHistory();
  }

  /// 🔹 Gọi API để lấy lịch sử điểm danh
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classSectionId = widget.course['class_section_id'];
      if (classSectionId == null) {
        throw Exception("Thiếu class_section_id");
      }

      // API route: /api/student/class-sections/123/attendance
      final res = await ApiClient().dio.get(
        "${AppConfig.BASE_URL}${AppConfig.studentHistoryPath}/$classSectionId/attendance",
      );

      if (mounted) {
        setState(() {
          _history = (res.data['data'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.response?.data.toString() ?? e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 🔹 Tính toán số liệu thống kê
  int get totalSessions => _history.length;
  int get attendedSessions => _history.where((s) {
    return s['status'] == 'present' || s['status'] == 'late';
  }).length;

  /// 🔹 Định dạng ngày tháng (vd: "Thứ Hai - 13/10/25")
  String _formatDate(DateTime date) {
    // 'EEEE' sẽ cho ra "Thứ Hai", "Thứ Ba"... (nhờ defaultLocale = 'vi_VN')
    final dayOfWeek = DateFormat('EEEE').format(date);
    final dayMonthYear = DateFormat('dd/MM/yy').format(date);
    return '$dayOfWeek - $dayMonthYear';
  }

  /// 🔹 CẬP NHẬT: Widget hiển thị trạng thái (theo ảnh mới)
  Widget _buildStatusWidget(String status, DateTime date) {
    final now = DateTime.now();
    // Chỉ so sánh ngày (bỏ qua giờ)
    final isToday = DateUtils.isSameDay(date, now);

    switch (status) {
      case 'present':
        return const Text(
          "Có mặt",
          style: TextStyle(color: Colors.black, fontSize: 16),
        );
      case 'late':
        return const Text(
          "Trễ", // Giữ lại logic này
          style: TextStyle(
              color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
        );
      case 'absent':
        return const Text(
          "Vắng", // Giữ lại logic này
          style: TextStyle(
              color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        );

    // Logic cho "ĐIỂM DANH", "?", và "Vắng" (nếu quá hạn)
      case 'pending':
      default:
        if (isToday) {
          // 1. Nếu là hôm nay -> "ĐIỂM DANH"
          return const Text(
            "ĐIỂM DANH",
            style: TextStyle(
                color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
          );
        } else if (date.isAfter(now)) {
          // 2. Nếu là ngày tương lai -> "?"
          return const Text(
            "?",
            style: TextStyle(color: Colors.black, fontSize: 16),
          );
        } else {
          // 3. Nếu là ngày trong quá khứ (đã qua) -> "Vắng"
          return Text(
            "Vắng",
            style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 16,
                fontWeight: FontWeight.normal),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin tĩnh từ 'widget.course' (do API lịch học trả về)
    final String courseName = widget.course['course_name'] ?? 'Chi tiết môn học';
    final String className = widget.course['class_name'] ?? '--';

    return Scaffold(
      // CẬP NHẬT: AppBar
      appBar: AppBar(
        title: const Text("Trang chủ"),
        backgroundColor: Colors.white,
        elevation: 0, // Bỏ bóng
        foregroundColor: Colors.black, // Màu chữ/icon
      ),
      // CẬP NHẬT: Màu nền
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CẬP NHẬT: Thẻ thông tin môn học (theo ảnh)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Thêm margin
            decoration: BoxDecoration(
              color: Colors.grey[200], // Màu nền xám
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName, // Dữ liệu này LẤY TỪ VIEW
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Lớp: $className", // Dữ liệu này LẤY TỪ VIEW
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ],
            ),
          ),

          // CẬP NHẬT: Danh sách lịch sử điểm danh
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // Tách riêng widget để xử lý loading/error/data
              child: _buildHistoryList(),
            ),
          ),

          // CẬP NHẬT: Thống kê (đặt ở dưới cùng)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 16),
                // Chỉ hiển thị khi load xong và không lỗi
                if (!_isLoading && _error == null) ...[
                  Text(
                    "Số buổi đã điểm danh: $attendedSessions/$totalSessions",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tổng số buổi: $totalSessions",
                    style: const TextStyle(fontSize: 16),
                  ),
                ] else if (_isLoading) ...[
                  // Hiển thị placeholder khi đang load
                  const Text("Đang tải thống kê...",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Widget hiển thị danh sách (loading, error, data)
  Widget _buildHistoryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Lỗi tải lịch sử: $_error",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text("Thử lại"),
            )
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return const Center(child: Text("Chưa có buổi điểm danh nào."));
    }

    // CẬP NHẬT: Hiển thị danh sách (không bọc trong Card)
    return ListView.separated(
      itemCount: _history.length,
      separatorBuilder: (context, index) =>
      const SizedBox(height: 20), // Tăng khoảng cách
      itemBuilder: (context, index) {
        final session = _history[index];
        final sessionDate = DateTime.parse(session['date']);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ngày tháng
            Text(
              _formatDate(sessionDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Trạng thái
            _buildStatusWidget(
              session['status'],
              sessionDate,
            ),
          ],
        );
      },
    );
  }
}