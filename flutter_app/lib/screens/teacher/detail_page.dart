// detail_page.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../services/attendance_service.dart';
import '../../models/session_detail.dart';
import '../../models/student.dart'; // Đảm bảo import này đúng

class DetailPage extends StatefulWidget {
  final String courseTitle;
  final String sessionId; // ID này là attendance_session_id

  const DetailPage({
    super.key,
    required this.courseTitle,
    required this.sessionId,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final sec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // Trạng thái lọc
  String _selectedFilter = 'Tất cả';

  // === SỬA 1: ĐỔI LẠI THÀNH MỘT ĐỐI TƯỢNG ===
  // Trang này chỉ hiển thị chi tiết CỦA MỘT buổi học
  SessionDetail? _sessionDetail; // <--- SỬA Ở ĐÂY
  bool _loading = true;
  String? _error;

  // Danh sách dự phòng (dùng khi _sessionDetail.students là null)
  final List<Student> allStudents = [];

  @override
  void initState() {
    super.initState();
    print("Mở DetailPage với sessionId: ${widget.sessionId}");
    _loadSessionDetail();

  }

  Future<void> _loadSessionDetail() async {
    // Kiểm tra an toàn: Đảm bảo sessionId không bị null
    if (widget.sessionId.isEmpty) {
      setState(() {
        _loading = false;
        _error = "Lỗi: Không nhận được ID của buổi học.";
      });
      return;
    }

    // Đặt lại trạng thái loading
    if (!_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // === SỬA 2: GỌI HÀM getSessionDetail (trả về 1 Map) ===
      // Hàm này gọi API (GET /api/attendance/session/{id})
      final detail = await AttendanceService().getSessionDetail(widget.sessionId);

      if (mounted) {
        setState(() {
          // === SỬA 3: GÁN VÀO BIẾN _sessionDetail ===
          _sessionDetail = detail; // <--- SỬA Ở ĐÂY
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is DioError) {
            _error = e.response?.data['message'] ?? e.message;
          } else {
            _error = e.toString();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // === CÁC HÀM BÊN DƯỚI ĐÃ CHẠY ĐÚNG VỚI _sessionDetail ===

  // Lấy danh sách sinh viên dựa trên bộ lọc
  List<Student> getFilteredStudents() {
    // Nguồn: Lấy danh sách 'students' TỪ BÊN TRONG _sessionDetail
    final source = _sessionDetail?.students ?? allStudents;
    if (_selectedFilter == 'Tất cả') return source;

    // Logic lọc của bạn (đã ổn)
    String filterStatus;
    switch (_selectedFilter) {
      case 'Có mặt':
        filterStatus = 'present';
        break;
      case 'Vắng':
        filterStatus = 'absent';
        break;
      case 'Muộn':
        filterStatus = 'late';
        break;
      default:
        return source; // Trả về 'Tất cả' nếu filter không khớp
    }
    return source.where((s) => s.status == filterStatus).toList();
  }

  // Đếm số lượng
  // Các hàm này giờ đã đúng vì _sessionDetail là 1 object
  int get presentCount => _sessionDetail?.presentCount ?? 0;
  int get absentCount => _sessionDetail?.absentCount ?? 0;
  int get lateCount => _sessionDetail?.lateCount ?? 0;

  // Widget cho chip lọc (Không đổi)
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
      selectedColor: const Color(0xFFD1C4E9),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4527A0) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // Lấy màu cho trạng thái (Không đổi)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  // Lấy text hiển thị cho trạng thái (Không đổi)
  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'Có mặt';
      case 'absent':
        return 'Vắng';
      case 'late':
        return 'Muộn';
      default:
        return 'N/A'; // 'N/A' = Not Available
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách sinh viên đã lọc (đã đúng)
    final filteredStudents = getFilteredStudents();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.courseTitle,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _loadSessionDetail,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      // === THAY ĐỔI DUY NHẤT: THÊM SAFEAREA ===
      body: SafeArea(
        child: Column(
          children: [
            // Phần lọc (đã ổn)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFilterChip('Tất cả'),
                  _buildFilterChip('Có mặt'),
                  _buildFilterChip('Vắng'),
                  _buildFilterChip('Muộn'),
                ],
              ),
            ),
            const Divider(height: 1),

            // Phần hiển thị Bảng (đã ổn)
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center( // Hiển thị lỗi
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Lỗi khi tải dữ liệu:\n$_error',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadSessionDetail,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
              // Thêm kiểm tra nếu _sessionDetail vẫn là null
                  : _sessionDetail == null
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không nhận được dữ liệu.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadSessionDetail,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
              // Nếu có dữ liệu, hiển thị DataTable
                  : SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 16.0,
                  headingRowColor:
                  MaterialStateProperty.all(Colors.grey[100]),
                  columns: const [
                    DataColumn(
                        label: Text('STT',
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Họ Tên',
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Trạng thái',
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Giờ điểm danh',
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                  ],
                  // Dùng 'filteredStudents' đã được lọc
                  rows:
                  filteredStudents.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final student = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(index.toString())),
                      DataCell(Text(student.name)),
                      DataCell(
                        Text(
                          _getStatusText(student.status ?? 'Vắng'),
                          style: TextStyle(
                            color: _getStatusColor(student.status ?? 'Vắng'),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(Text(student.checkInTime ?? '--')),
                    ]);
                  }).toList(),
                ),
              ),
            ),

            const Divider(height: 1),

            // Phần tổng kết (đã ổn)
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Có mặt: $presentCount',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Vắng: $absentCount', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Muộn: $lateCount', style: const TextStyle(fontSize: 16)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}