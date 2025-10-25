import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart'; // dùng format ngày

import '../../api/api_client.dart';
import '../../utils/config.dart';
import '../../models/user.dart';
import 'create_session_page.dart';
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

  // trạng thái ngày đang xem
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load(); // mặc định load hôm nay
  }

  // _load nhận ngày (optional) và gọi API với ?date=YYYY-MM-DD
  Future<void> _load([DateTime? date]) async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final d = date ?? _selectedDate;
      final ymd = DateFormat('yyyy-MM-dd').format(d);

      final res = await _dio.get(
        AppConfig.teacherSchedulePath,
        queryParameters: {'date': ymd},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final List data = res.data as List;
      schedule = data.cast<Map<String, dynamic>>();
      _selectedDate = d;
      selectedDay = d.weekday;
    } on DioException catch (e) {
      err = 'Lỗi tải lịch: ${e.response?.statusCode ?? e.type.name}';
    } catch (e) {
      err = 'Lỗi: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // dùng getter để không “đóng băng” state
  List<Widget> get _pages => [
        TeacherHomeContent(
          schedule: schedule,
          loading: loading,
          err: err,
          selectedDay: selectedDay,
          onPickDate: (d) async {
            await _load(d);
          },
          onRefresh: () => _load(_selectedDate),
          selectedDate: _selectedDate,
        ),
        const _HistoryPlaceholder(),
        const SettingsPage(),
      ];

  List<String> get _pageTitles => const ['Trang chủ', 'Lịch sử', 'Cài đặt'];

  AppBar _buildAppBar() {
    if (_currentIndex == 0) {
      // Trang chủ: hiển thị thông tin user
      return AppBar(
        automaticallyImplyLeading: false, // Không có nút back
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 1,
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
                  widget.user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Text('Giảng viên',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            )
          ],
        ),
      );
    } else {
      // Các trang khác: hiển thị tiêu đề
      return AppBar(
        automaticallyImplyLeading: false, // Không có nút back
        title: Text(_pageTitles[_currentIndex]),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEAFF),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF7A6EF3),
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
// Content
// ============================================================================

class TeacherHomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> schedule;
  final bool loading;
  final String? err;
  final int selectedDay; // 1..7 (T2..CN)
  final Future<void> Function() onRefresh;

  // chọn ngày theo DateTime
  final Future<void> Function(DateTime day) onPickDate;
  final DateTime selectedDate;

  const TeacherHomeContent({
    super.key,
    required this.schedule,
    required this.loading,
    required this.err,
    required this.selectedDay,
    required this.onRefresh,
    required this.onPickDate,
    required this.selectedDate,
  });

  DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

  // strip 14 ngày, bấm là gọi onPickDate(d)
  Widget _dayStrip(BuildContext context) {
    final days =
        List<DateTime>.generate(14, (i) => DateTime.now().add(Duration(days: i)));
    String label(DateTime d) {
      const wd = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
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

  // ---------------- UI helpers ----------------
  String _hhmm(String t) {
    if (t.isEmpty) return '';
    final parts = t.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return t;
  }

  String _periodOrTime(String start, String end, String? periodText) {
    if (periodText != null && periodText.trim().isNotEmpty) return periodText;
    if (start.isEmpty || end.isEmpty) return '';
    return '${_hhmm(start)}-${_hhmm(end)}';
  }

  String _statusByTime(String start, String end, DateTime day) {
    try {
      if (start.isEmpty || end.isEmpty) return 'next';
      final sParts = start.split(':');
      final eParts = end.split(':');
      final s = DateTime(
          day.year, day.month, day.day, int.parse(sParts[0]), int.parse(sParts[1]));
      final e = DateTime(
          day.year, day.month, day.day, int.parse(eParts[0]), int.parse(eParts[1]));
      final now = DateTime.now();
      if (now.isBefore(s)) return 'next';
      if (now.isAfter(e)) return 'done';
      return 'current';
    } catch (_) {
      return 'next';
    }
  }
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // strip 14 ngày
        _dayStrip(context),

        // Thanh điều khiển ngày: ←  dd/MM/yyyy  →  + date picker + refresh
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Hôm trước',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onPickDate(_addDays(selectedDate, -1)),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Lịch ngày ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hôm sau',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onPickDate(_addDays(selectedDate, 1)),
              ),
              IconButton(
                tooltip: 'Chọn ngày',
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) await onPickDate(d);
                },
              ),
              IconButton(
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
                          FilledButton(
                              onPressed: onRefresh, child: const Text('Thử lại')),
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

                            final course = (s['course_name'] ?? 'Môn học') as String;
                            final className = (s['class_names'] ?? '') as String;
                            final room = (s['room'] ?? '') as String;
                            final start = (s['start_time'] ?? '') as String;
                            final end = (s['end_time'] ?? '') as String;
                            final periodTxt =
                                _periodOrTime(start, end, s['period']?.toString());
                            final status = (s['status'] ??
                                _statusByTime(start, end, selectedDate))
                                as String;

                            final dayLabel =
                                '${selectedDate.month}/${selectedDate.day}';

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: ScheduleCard(
                                title: '$course ($dayLabel)',
                                subtitle: className,
                                room: room.isNotEmpty ? room : '—',
                                periodText: periodTxt,
                                timeText: _hhmm(start),
                                status: status, // 'current' | 'next' | 'done'
                                onTap: () {
                                  final csId = (s['class_section_id'] as num?)?.toInt();
                                  if (csId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Thiếu tên lớp học phần')),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateSessionPage(schedule: s),
                                    ),
                                  );
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
class ScheduleCard extends StatelessWidget {
  final String title;       // "CSE441 Mobile App (9/25)"
  final String subtitle;    // "64KTPM3 + 64KTPM-NB"
  final String room;        // "P329 A2"
  final String periodText;  // "T 3–4" hoặc "08:45-10:35"
  final String timeText;    // "08:45"
  final String status;      // 'current' | 'next' | 'done'
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.room,
    required this.periodText,
    required this.timeText,
    required this.status,
    this.onTap,
  });

  Color _dotColor() {
    switch (status) {
      case 'current':
        return Colors.yellow; // đang học
      case 'next':
        return Colors.green; // sắp tới
      case 'done':
        return Colors.red; // đã xong
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nội dung trái
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Hàng icon: phòng + tiết
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            room,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          periodText,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Cột giờ + chấm màu
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(radius: 8, backgroundColor: _dotColor()),
                ],
              ),
            ],
          ),
        ),
      ),
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
