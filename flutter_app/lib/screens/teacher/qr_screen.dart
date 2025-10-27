import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQrPage extends StatefulWidget {
  final Map<String, dynamic> session;

  const ShowQrPage({super.key, required this.session});

  @override
  State<ShowQrPage> createState() => _ShowQrPageState();
}

class _ShowQrPageState extends State<ShowQrPage> {
  late String qrData;
  int remainingSeconds = 600; // ⏱️ 10 phút mặc định
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // ✅ Lấy token hoặc ID từ session
    qrData = widget.session['token'] != null
        ? widget.session['token']
        : "https://103.75.183.227/attendance/session/${widget.session['id']}";

    // ✅ Bắt đầu đếm ngược thời gian nếu có thời gian kết thúc
    if (widget.session['end_at'] != null && widget.session['start_at'] != null) {
      final start = DateTime.tryParse(widget.session['start_at']);
      final end = DateTime.tryParse(widget.session['end_at']);
      if (start != null && end != null) {
        final diff = end.difference(DateTime.now()).inSeconds;
        if (diff > 0) remainingSeconds = diff;
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        timer.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phiên điểm danh đã kết thúc!')),
        );
        Navigator.pop(context);
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final sec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Scaffold(
      appBar: AppBar(
        title: Text("Mã QR - ${session['course_name'] ?? 'Phiên điểm danh'}"),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🕒 Đếm ngược thời gian
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Thời gian còn lại: ${formatDuration(remainingSeconds)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 📱 Mã QR
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 260.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 24),

                // 🔍 Thông tin phiên
                Text(
                  "Môn học: ${session['course_name'] ?? 'Không rõ'}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Giảng viên: ${session['teacher_name'] ?? '—'}"),
                const SizedBox(height: 8),
                Text("Phòng học: ${session['room'] ?? '—'}"),
                const SizedBox(height: 8),
                Text("Mã phiên: ${session['id'] ?? '—'}"),
                const SizedBox(height: 24),

                // ✅ Nút kết thúc phiên thủ công
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phiên điểm danh đã kết thúc')),
                    );
                  },
                  label: const Text(
                    "Kết thúc phiên điểm danh",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
