import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../api/api_client.dart';
import '../../utils/config.dart';
import '../../models/user.dart';
import 'qr_scan_page.dart';
import 'package:intl/intl.dart';
import 'course_detail_page.dart';
import '../setting_page.dart';
import 'face_scan_page.dart'; // 2. Thêm file quét mặt
import 'student_checkin_loading_page.dart'; // 3. Thêm file tải trung gian
import 'dart:io';

class StudentHome extends StatefulWidget {
  final AppUser user;
  const StudentHome({super.key, required this.user});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  DateTime selectedDate = DateTime.now();
  // Biến này giờ chỉ dùng để xác định icon nào đang được chọn (luôn là Home)
  final int currentIndex = 0;

  // 🔹 Lấy danh sách thứ trong tuần
  List<DateTime> getWeekDays(DateTime base) {
    final monday = base.subtract(Duration(days: base.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  // 🔹 Chỉ thay đổi ngày (không load lại toàn bộ widget)
  void _changeDay(DateTime date) => setState(() => selectedDate = date);

  void _changeBy(int days) =>
      setState(() => selectedDate = selectedDate.add(Duration(days: days)));

  // 🔹 Hàm đổi màu theo trạng thái buổi học
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

  // 🔹 Hàm fetch dữ liệu (chỉ dùng riêng cho FutureBuilder)
  Future<List<Map<String, dynamic>>> _fetchSchedule() async {
    try {
      final res = await ApiClient().dio.get(
        "${AppConfig.BASE_URL}${AppConfig.studentSchedulePath}",
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

  @override
  Widget build(BuildContext context) {
    final weekDays = getWeekDays(selectedDate);
    final daysLabel = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // 👇 2. BỎ INDEXEDSTACK, chỉ hiển thị trang home
        child: _buildHomePage(weekDays, daysLabel),
      ),

      // 🔹 Thanh điều hướng dưới cùng
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
            // --- XỬ LÝ NHẤN VÀO ICON QR (index 1) ---
            if (index == 1) {

              // 1. Mở trang Quét QR (dùng file của bạn) và đợi kết quả (token)
              // ‼️ Chú ý: Chúng ta gọi với returnData: true
              final String? qrToken = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => const QrScanPage(returnData: true),
                ),
              );

              // 2. Nếu người dùng bấm Back, dừng lại
              if (qrToken == null || !context.mounted) return;

              // 3. Mở trang Quét Mặt (file mới) và đợi kết quả (ảnh)
              final File? facePhoto = await Navigator.push<File>(
                context,
                MaterialPageRoute(
                  builder: (_) => const FaceScanPage(),
                ),
              );

              // 4. Nếu người dùng bấm Back, dừng lại
              if (facePhoto == null || !context.mounted) return;

              // 5. Mở trang TẢI DỮ LIỆU TRUNG GIAN (file mới)
              // Trang này sẽ giải mã QR, lấy session, rồi chuyển tiếp
              // sang StudentCheckinPage (file của bạn)
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentCheckinLoadingPage(
                    qrToken: qrToken,
                    facePhoto: facePhoto,
                  ),
                ),
              );
            }
            // --- XỬ LÝ NHẤN VÀO ICON CÀI ĐẶT (index 2) ---
            else if (index == 2) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
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

  // Hàm _buildHomePage không có gì thay đổi
  Widget _buildHomePage(List<DateTime> weekDays, List<String> daysLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Thông tin sinh viên
        Container(
          color: Colors.deepPurple.shade200,
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name ?? "Sinh viên",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text("Sinh viên", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),

        // 🔹 Dãy chọn thứ
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
                    onTap: () => _changeDay(date),
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

        // 🔹 Thanh tiêu đề ngày hiện tại
        Container(
          color: Colors.purple.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeBy(-1),
                ),
                Text(
                  "Lịch ngày ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeBy(1),
                ),
              ]),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Tải lại lịch học',
                    onPressed: () {
                      setState(() {}); // chỉ reload phần FutureBuilder
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    tooltip: 'Chọn ngày khác',
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2026),
                        locale: const Locale('vi', 'VN'),
                      );
                      if (picked != null) _changeDay(picked);
                    },
                  ),

                ],
              )
            ],
          ),
        ),


        // 🔹 Danh sách lịch học (chỉ phần này load lại khi đổi ngày)
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchSchedule(),
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
                      ? _statusColor(startTime)
                      : Colors.grey;
                  final formattedTime = startTime != null
                      ? DateFormat.Hm().format(startTime)
                      : '--:--';

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          Text(formattedTime, style: const TextStyle(fontSize: 14)),
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
      ],
    );
  }
}