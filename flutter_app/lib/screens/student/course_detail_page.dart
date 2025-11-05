import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../api/api_client.dart';
import '../../utils/config.dart';

// 🎨 MỚI: Chỉ import FaceScan và CheckinPage
// (Đã xóa QrScanPage và StudentCheckinLoadingPage)
import 'face_scan_page.dart';
import 'student_checkin_page.dart';

class CourseDetailPage extends StatefulWidget {
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

  // 🎨 MỚI: Hàm xử lý quy trình (Flow) quét mặt
  // (Bỏ qua hoàn toàn QR và Loading Page)
  Future<void> _startFaceScanFlow(Map<String, dynamic> session) async {
    print("===== DỮ LIỆU BUỔI HỌC (SESSION): $session =====");
    if (!mounted) return;

    // 1. Mở trang Quét Mặt (đây là "máy ảnh")
    final File? facePhoto = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceScanPage(),
      ),
    );
    if (facePhoto == null || !mounted) return; // Người dùng bấm back

    // 2. TẠO DỮ LIỆU BUỔI HỌC (SESSION DATA) MỚI
    // Lấy thông tin chung của MÔN HỌC (từ widget.course)
    // và trộn với thông tin của BUỔI HỌC (từ session)
    final Map<String, dynamic> sessionData = {
      'course_name': widget.course['course_name'],
      'class_name': widget.course['class_names'],
      'course_code': widget.course['course_code'],

      // Dữ liệu từ BUỔI HỌC (session lấy từ _history)
      'date': session['date'],
      'status': session['status'],

      // Key đúng (theo log) là 'session_id'
      'session_id': session['session_id'],
    };

    // 3. Mở thẳng trang StudentCheckinPage
    //    (Bỏ qua StudentCheckinLoadingPage)
    //    Chúng ta dùng 'await' để chờ trang này đóng lại
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCheckinPage(
          session: sessionData, // Truyền dữ liệu đã trộn
          photo: facePhoto,
        ),
      ),
    );

    // 4. Tải lại lịch sử để cập nhật "Có mặt"
    //    (Sau khi trang StudentCheckinPage đóng lại)
    await _loadHistory();
  }


  /// 🔹 Tính toán số liệu thống kê
  int get totalSessions => _history.length;
  int get attendedSessions => _history.where((s) {
    return s['status'] == 'present' || s['status'] == 'late';
  }).length;

  /// 🔹 Định dạng ngày tháng
  String _formatDate(DateTime date) {
    final dayOfWeek = DateFormat('EEEE').format(date);
    final dayMonthYear = DateFormat('dd/MM/yy').format(date);
    return '$dayOfWeek - $dayMonthYear';
  }

  /// 🔹 CẬP NHẬT: Widget hiển thị trạng thái
  Widget _buildStatusWidget(Map<String, dynamic> session, DateTime date) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(date, now);
    final status = session['status']; // Lấy status từ session

    switch (status) {
      case 'present':
        return const Text(
          "Có mặt",
          style: TextStyle(color: Colors.black, fontSize: 16),
        );
      case 'late':
        return const Text(
          "Trễ",
          style: TextStyle(
              color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
        );
      case 'absent':
        return const Text(
          "Vắng",
          style: TextStyle(
              color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        );

      case 'pending':
      default:
        if (isToday) {
          // 1. "ĐIỂM DANH" (Button)
          return TextButton(
            // 🎨 MỚI: Gọi hàm _startFaceScanFlow và truyền 'session'
            onPressed: () => _startFaceScanFlow(session),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerRight,
            ),
            child: const Text(
              "ĐIỂM DANH",
              style: TextStyle(
                  color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        } else if (date.isAfter(now)) {
          // 2. Nếu là ngày tương lai -> "?"
          return const Text(
            "?",
            style: TextStyle(color: Colors.black, fontSize: 16),
          );
        } else {
          // 3. Nếu là ngày trong quá khứ -> "Vắng"
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
    final String courseName = widget.course['course_name'] ?? 'Chi tiết môn học';
    final String className = widget.course['class_name'] ?? '--';

    return Scaffold(
      // --- 1. APP BAR ---
      appBar: AppBar(
        title: const Text("Trang chủ"),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 1,
      ),

      // --- 2. NỀN TRẮNG ---
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // --- 3. THẺ THÔNG TIN MÔN HỌC ---
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Lớp: $className",
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 16),

                // --- 4. DANH SÁCH LỊCH SỬ (BÊN TRONG THẺ) ---
                _buildHistoryList(),
              ],
            ),
          ),

          // --- 5. THỐNG KÊ (Ở DƯỚI CÙNG) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 16),
                if (!_isLoading && _error == null) ...[
                  Text(
                    "Số buổi đã điểm danh: $attendedSessions/$totalSessions",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tổng số buổi: $totalSessions",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ] else if (_isLoading) ...[
                  const Text("Đang tải thống kê...",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ]
              ],
            ),
          ),

          const Spacer(),
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

    return ListView.separated(
      itemCount: _history.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) =>
      const SizedBox(height: 20),
      itemBuilder: (context, index) {
        // 🎨 MỚI: Lấy toàn bộ 'session'
        final session = _history[index];
        final sessionDate = DateTime.tryParse(session['date'] ?? '');
        if (sessionDate == null) return const SizedBox.shrink();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ngày tháng
            Text(
              _formatDate(sessionDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            // Trạng thái
            // 🎨 MỚI: Truyền toàn bộ 'session'
            _buildStatusWidget(
              session,
              sessionDate,
            ),
          ],
        );
      },
    );
  }
}