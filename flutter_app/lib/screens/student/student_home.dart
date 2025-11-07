import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../api/api_client.dart';
import '../../utils/config.dart';
import '../../models/user.dart';
import 'qr_scan_page.dart';
import 'package:intl/intl.dart';
import 'course_detail_page.dart';
import '../setting_page.dart';
import 'face_scan_page.dart';
import 'student_checkin_loading_page.dart';
import 'dart:io';

// =========================================================================
// 1. WIDGET CHÍNH (CHỨA KHUNG VÀ TRẠNG THÁI)
// =========================================================================
class StudentHome extends StatefulWidget {
  final AppUser user;
  const StudentHome({super.key, required this.user});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  // _visualTabIndex: Nút nào đang sáng (0=Home, 1=QR, 2=Settings)
  // _pageIndex: Trang nội dung nào đang hiển thị (0=Home, 1=Settings)
  int _visualTabIndex = 0;
  int _pageIndex = 0;

  // --- Các state và hàm logic cho trang Home (tab 0) ---
  DateTime selectedDate = DateTime.now();

  List<DateTime> getWeekDays(DateTime base) {
    final monday = base.subtract(Duration(days: base.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  void _changeDay(DateTime date) => setState(() => selectedDate = date);

  void _changeBy(int days) =>
      setState(() => selectedDate = selectedDate.add(Duration(days: days)));

  Color _statusColor(DateTime start) {
    final now = DateTime.now();
    if (start.isBefore(now.subtract(const Duration(minutes: 15)))) {
      return Colors.red;
    } else if (start.isAfter(now.add(const Duration(minutes: 15)))) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Future<void> _onRefresh() async {
    setState(() {}); // Chỉ cần build lại để FutureBuilder chạy lại
  }

  Future<void> _onShowDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) _changeDay(picked);
  }

  Future<List<Map<String, dynamic>>> _fetchSchedule() async {
    try {
      final res = await ApiClient().dio.get(
        AppConfig.studentSchedulePath,
        queryParameters: {
          'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        },
      );
      print(res.data);
      if (res.statusCode == 200) {
        if (res.data is Map && res.data['data'] != null) {
          return (res.data['data'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        } else if (res.data is List) {
          return (res.data as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
      }
      throw Exception("Dữ liệu không hợp lệ hoặc lỗi máy chủ");
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  // --- Kết thúc logic trang Home ---

  // 🎨 KẾ THỪA (Giống TeacherHome): Getter cho danh sách các trang
  List<Widget> get _pages {
    // Tính toán dữ liệu cho trang Home
    final weekDays = getWeekDays(selectedDate);
    final daysLabel = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

    // 🎨 CẬP NHẬT: _pages chỉ chứa 2 trang nội dung
    return [
      // --- Trang 0: Trang chủ (Lịch học) ---
      _StudentHomeContent(
        selectedDate: selectedDate,
        weekDays: weekDays,
        daysLabel: daysLabel,
        fetchSchedule: _fetchSchedule,
        statusColor: _statusColor,
        onChangeDay: _changeDay,
        onChangeBy: _changeBy,
        onRefresh: _onRefresh,
        onShowDatePicker: _onShowDatePicker,
      ),
      // --- Trang 1: Cài đặt ---
      const SettingsPage(),
    ];
  }

  // 🎨 KẾ THỪA: Getter cho tiêu đề trang
  List<String> get _pageTitles => const ['Trang chủ', 'Cài đặt'];

  // 🎨 KẾ THỪA: Hàm build AppBar động
  AppBar _buildAppBar() {
    if (_pageIndex == 0) {
      // Trang chủ: hiển thị thông tin user
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name ?? "Sinh viên",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Text('Sinh viên',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            )
          ],
        ),
      );
    } else {
      // Các trang khác (Cài đặt): hiển thị tiêu đề
      return AppBar(
        automaticallyImplyLeading: false,
        title: Text(_pageTitles[_pageIndex]), // 🎨 Dùng _pageIndex
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 1,
      );
    }
  }

  // 🎨 HÀM HÀNH ĐỘNG: Xử lý quy trình quét QR
  Future<void> _startQRScanFlow() async {
    // 1. Mở trang Quét QR
    final String? qrToken = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        // Trang QrScanPage giờ đã tự có AppBar màu tím
        builder: (_) => const QrScanPage(returnData: true),
      ),
    );
    if (qrToken == null || !context.mounted) return;

    // 2. 🎨 SỬA: Mở trang Quét Mặt (nhận File)
    // FaceScanPage phải được sửa để trả về File (như trong hướng dẫn trước)
    final File? facePhoto = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceScanPage(),
      ),
    );
    if (facePhoto == null || !context.mounted) return;

    // 3. 🎨 SỬA: Mở trang Tải dữ liệu (truyền File)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCheckinLoadingPage(
          qrToken: qrToken,
          facePhoto: facePhoto, // 👈 Truyền File
        ),
      ),
    );
  }

  // 🔹 Hàm build() chính
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent,

      // --- TOP BAR (Kế thừa) ---
      appBar: _buildAppBar(),

      // --- NỘI DUNG (Kế thừa - Dùng IndexedStack) ---
      body: SafeArea(
        child: IndexedStack(
          index: _pageIndex, // 👈 Dùng _pageIndex (0 hoặc 1)
          children: _pages,  // 👈 Danh sách 2 trang
        ),
      ),

      // 🎨 CẬP NHẬT: BottomNavigationBar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.deepPurpleAccent,
        ),
        child: BottomNavigationBar(
          // 🎨 Dùng _visualTabIndex để tô sáng nút
          currentIndex: _visualTabIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.black54,
          type: BottomNavigationBarType.fixed,

          // 🎨 CẬP NHẬT: Logic onTap (Đã hoàn thiện)
          onTap: (tapIndex) async {

            if (tapIndex == 0) {
              setState(() {
                _visualTabIndex = 0; // Sáng nút Home
                _pageIndex = 0;      // Hiển thị trang Home
              });
            }
            // ---------------------------------
            // --- XỬ LÝ NHẤN VÀO ICON QR (index 1) ---
            else if (tapIndex == 1) {
              // 1. Sáng nút QR
              setState(() {
                _visualTabIndex = 1;
              });

              // 2. Chạy hàm quét
              await _startQRScanFlow();

              // 3. Sau khi quét xong, trả lại sáng nút Home
              if (mounted) {
                setState(() {
                  // Đặt lại visualTabIndex về trang đang hiển thị
                  _visualTabIndex = (_pageIndex == 0) ? 0 : 2;
                });
              }
            }
            // ---------------------------------
            // --- XỬ LÝ NHẤN VÀO ICON CÀI ĐẶT (index 2) ---
            else if (tapIndex == 2) {
              setState(() {
                _visualTabIndex = 2; // Sáng nút Settings
                _pageIndex = 1;      // Hiển thị trang Settings (trang thứ 2)
              });
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_2_outlined), // 👈 Nút QR
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
}

// =========================================================================
// 2. WIDGET NỘI DUNG (Widget con)
// =========================================================================
class _StudentHomeContent extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> weekDays;
  final List<String> daysLabel;
  final Future<List<Map<String, dynamic>>> Function() fetchSchedule;
  final Color Function(DateTime) statusColor;
  final void Function(DateTime) onChangeDay;
  final void Function(int) onChangeBy;
  final VoidCallback onRefresh;
  final VoidCallback onShowDatePicker;

  const _StudentHomeContent({
    required this.selectedDate,
    required this.weekDays,
    required this.daysLabel,
    required this.fetchSchedule,
    required this.statusColor,
    required this.onChangeDay,
    required this.onChangeBy,
    required this.onRefresh,
    required this.onShowDatePicker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.purple.shade50,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weekDays.map((date) {
                final isSelected = DateUtils.isSameDay(date, selectedDate);
                final weekday = daysLabel[date.weekday - 1];
                final text = "$weekday ${date.day}/${date.month}";
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onChangeDay(date),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pink.shade200 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                          isSelected ? Colors.pink : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Container(
          color: Colors.purple.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => onChangeBy(-1),
                ),
                Text(
                  "Lịch ngày ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => onChangeBy(1),
                ),
              ]),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    tooltip: 'Chọn ngày khác',
                    onPressed: onShowDatePicker,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Tải lại lịch học',
                    onPressed: onRefresh,
                  ),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchSchedule(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Lỗi tải lịch: ${snapshot.error}",
                          textAlign: TextAlign.center));
                }
                final schedule = snapshot.data ?? [];
                if (schedule.isEmpty) {
                  return const Center(
                      child: Text("Không có lịch học cho ngày này."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: schedule.length,
                  itemBuilder: (ctx, i) {
                    final s = schedule[i];
                    final startTime = DateTime.tryParse(s['start_time'] ?? '');
                    final color = startTime != null
                        ? statusColor(startTime)
                        : Colors.grey;
                    final formattedTime = startTime != null
                        ? DateFormat.Hm().format(startTime)
                        : '--:--';
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailPage(course: s),
                            ),
                          );
                        },
                        title: Text(
                          s['course_name'] ?? 'Không rõ môn học',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Phòng: ${s['room'] ?? '--'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formattedTime,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Icon(Icons.circle, color: color, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}