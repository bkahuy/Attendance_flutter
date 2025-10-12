import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/teacher_repository.dart';
import '../../widgets/date_picker_row.dart';
import 'create_session_sheet.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});
  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _repo = TeacherRepository();
  DateTime _date = DateTime.now();
  List<dynamic> _items = [];
  bool _loading = false;
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _repo.schedule(DateFormat('yyyy-MM-dd').format(_date));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Giảng viên')),
        body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              DatePickerRow(
                  date: _date,
                  onChanged: (d) {
                    setState(() => _date = d);
                    _load();
                  }),
              const SizedBox(height: 8),
              Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final it = _items[i] as Map<String, dynamic>;
                            final course =
                                (it['course'] as Map?)?['name'] ?? 'Môn học';
                            final term = it['term'] ?? '';
                            final room = it['room'] ?? '';
                            return Card(
                                child: ListTile(
                              title: Text('$course ($term)'),
                              subtitle: Text('Phòng: $room | Lớp #${it['id']}'),
                              trailing: ElevatedButton(
                                child: const Text('Tạo điểm danh'),
                                onPressed: () {
                                  showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) {
                                        return Padding(
                                            padding: EdgeInsets.only(
                                                bottom: MediaQuery.of(context)
                                                    .viewInsets
                                                    .bottom),
                                            child: CreateSessionSheet(
                                                classSectionId:
                                                    it['id'] as int));
                                      });
                                },
                              ),
                            ));
                          }))
            ])));
  }
}
