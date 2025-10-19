import 'package:flutter/material.dart';

class CreateSessionPage extends StatefulWidget {
  final Map<String, dynamic> schedule;
  const CreateSessionPage({super.key, required this.schedule});

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _passController = TextEditingController();
  int _selectedDuration = 10;

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    final course = s['course_name'] ?? '—';
    final period = s['period'] ?? '—';
    final room = s['room'] ?? '—';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tạo phiên điểm danh'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Header thông tin lớp
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Môn: $course'),
                    Text('Tiết: $period'),
                    Text('Phòng: $room'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Mật khẩu
              const Text('Mật khẩu:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Chọn thời gian
              const Text('Thời gian điểm danh:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [5, 10, 15].map((m) {
                  final selected = _selectedDuration == m;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDuration = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? Colors.deepPurpleAccent : Colors.grey[300],
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '$m phút',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // 🔹 Nút tạo mã QR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Gọi API tạo phiên điểm danh
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã tạo mã QR và bắt đầu điểm danh')),
                    );
                  },
                  child: const Text(
                    'Tạo mã QR và bắt đầu điểm danh',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
