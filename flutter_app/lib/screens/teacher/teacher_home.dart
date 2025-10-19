import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart'; // [NEW] dùng format ngày

import '../../api/api_client.dart';
import '../../utils/config.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import 'create_session_sheet.dart';
import '../setting_page.dart';

class TeacherHome extends StatefulWidget {
  final AppUser user;
  const TeacherHome({super.key, required this.user});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final _dio = ApiClient().dio;

  // state dùng chung
  List<Map<String, dynamic>> schedule = [];
  bool loading = true;
  String? err;
  int selectedDay = DateTime.now().weekday;
  int _currentIndex = 0;

  // [NEW] trạng thái ngày được chọn thực sự (YYYY-MM-DD)
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load(); // mặc định load hôm nay
  }

  // [CHANGED] _load nhận ngày (optional) và gọi API với ?date=YYYY-MM-DD
  Future<void> _load([DateTime? date]) async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final d = date ?? _selectedDate;                                   // [NEW]
      final ymd = DateFormat('yyyy-MM-dd').format(d);                    // [NEW]

      final res = await _dio.get(
        AppConfig.teacherSchedulePath,
        queryParameters: {'date': ymd},                                  // [CHANGED]
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final List data = res.data as List;
      schedule = data.cast<Map<String, dynamic>>();
      _selectedDate = d;                                                 // [NEW]
      selectedDay = d.weekday;                                           // [NEW] đồng bộ hiển thị nếu cần
    } on DioException catch (e) {
      err = 'Lỗi tải lịch: ${e.response?.statusCode ?? e.type.name}';
    } catch (e) {
      err = 'Lỗi: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ====== PAGES (Indexed) ====================================================
  List<Widget> get _pages => [
    TeacherHomeContent(
      user: widget.user,
      schedule: schedule,
      loading: loading,
      err: err,
      selectedDay: selectedDay,
      onPickDate: (d) async { await _load(d); },  // luôn gọi version mới nhất
      onRefresh: () => _load(_selectedDate),
      selectedDate: _selectedDate,
    ),
    const _HistoryPlaceholder(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFEDEAFF),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFFB3A8F7),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

// ============================================================================
// Widget con giữ NGUYÊN giao diện cũ + bổ sung strip chọn ngày theo DATE
// ============================================================================

class TeacherHomeContent extends StatelessWidget {
  final AppUser user;
  final List<Map<String, dynamic>> schedule;
  final bool loading;
  final String? err;
  final int selectedDay; // 1..7 (T2..CN)
  final Future<void> Function() onRefresh;

  // [NEW] chọn ngày theo DateTime
  final Future<void> Function(DateTime day) onPickDate;
  final DateTime selectedDate; // [NEW]

  // [NEW] helper đổi ngày
  DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  const TeacherHomeContent({
    super.key,
    required this.user,
    required this.schedule,
    required this.loading,
    required this.err,
    required this.selectedDay,
    required this.onRefresh,
    // [NEW]
    required this.onPickDate,
    required this.selectedDate,
  });

  // [NEW] strip 14 ngày, bấm là gọi onPickDate(d)
  Widget _dayStrip(BuildContext context) {
    final days = List<DateTime>.generate(14, (i) => DateTime.now().add(Duration(days: i)));
    String label(DateTime d) {
      const wd = ['CN','T2','T3','T4','T5','T6','T7'];
      return '${wd[d.weekday % 7]} ${d.day}/${d.month}';
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final d = days[i];
          final isActive = DateUtils.isSameDay(d, selectedDate);
          return ChoiceChip(
            label: Text(label(d)),
            selected: isActive,
            selectedColor: const Color(0xFFE57373),
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => onPickDate(d),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [CHANGED] bỏ chip T2..CN cũ, thay bằng strip 14 ngày
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          color: const Color(0xFF7A6EF3),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.grey, size: 32),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const Text('Giảng viên', style: TextStyle(color: Colors.white70)),
                ],
              )
            ],
          ),
        ),

        // [CHANGED] Thanh chọn ngày theo DATE (14 ngày)
        _dayStrip(context),

        // [CHANGED] Thanh điều khiển ngày: ←  dd/MM/yyyy  →   + nút mở lịch
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              IconButton( // [NEW] lùi 1 ngày
                tooltip: 'Hôm trước',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onPickDate(_addDays(selectedDate, -1)),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Lịch ngày ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton( // [NEW] tiến 1 ngày
                tooltip: 'Hôm sau',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onPickDate(_addDays(selectedDate, 1)),
              ),
              const SizedBox(width: 4),
              IconButton( // [NEW] mở date picker
                tooltip: 'Chọn ngày',
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    await onPickDate(d);
                  }
                },
              ),
              IconButton( // [NEW] refresh đúng ngày hiện tại đang xem
                tooltip: 'Tải lại',
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
              ),
            ],
          ),
        ),


        // Danh sách lịch
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : (err != null
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                FilledButton(onPressed: onRefresh, child: const Text('Thử lại')),
              ],
            ),
          )
              : (schedule.isEmpty
              ? const Center(child: Text('Không có lịch cho ngày này'))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: schedule.length,
            itemBuilder: (ctx, i) {
              final s = schedule[i];
              final title = s['course_name'] ?? 'Môn học';
              final room = s['room'] ?? '';
              final start = s['start_time'] ?? '';  // [CHANGED] show start/end rõ ràng
              final end   = s['end_time'] ?? '';
              final color = i == 0
                  ? Colors.green
                  : i == 1
                  ? Colors.amber
                  : Colors.red;

              return Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  title: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Phòng: $room • $start - $end',
                      style: const TextStyle(fontSize: 13)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(start.isEmpty ? '' : start,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      CircleAvatar(radius: 5, backgroundColor: color),
                    ],
                  ),
                  onTap: () async {
                    // mở sheet tạo phiên từ lớp được chọn
                    final csId = (s['class_section_id'] as num?)?.toInt();
                    if (csId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thiếu class_section_id')));
                      return;
                    }
                    final label =
                        '${s['course_name'] ?? 'Môn'} - ${s['room'] ?? ''} ($start-$end)';
                    final result = await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CreateSessionSheet(
                        classSectionId: csId,
                        courseLabel: label,
                      ),
                    );
                    if (result != null) {
                      final token = result['qr']?['token'];
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(token == null
                            ? 'Đã tạo phiên điểm danh'
                            : 'Đã tạo phiên — QR token: $token'),
                      ));
                    }
                  },
                ),
              );
            },
          ))),
        ),
      ],
    );
  }
}

// ============================================================================
// Placeholder cho tab Lịch sử (bạn thay bằng page thật sau)
// ============================================================================
class _HistoryPlaceholder extends StatelessWidget {
  const _HistoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Lịch sử điểm danh (đang để placeholder)'),
    );
  }
}
