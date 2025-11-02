import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/config.dart';
import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../utils/config.dart';

class ShowQrPage extends StatefulWidget {
  final Map<String, dynamic> session;
  const ShowQrPage({super.key, required this.session});

  @override
  State<ShowQrPage> createState() => _ShowQrPageState();
}

class _ShowQrPageState extends State<ShowQrPage> {
  late String qrData;
  int remainingSeconds = 0;
  Timer? _timer;

  DateTime? _startTime;
  DateTime? _endTime;

  String _statusMessage = "Đang tải...";
  bool _isClosing = false;

  final dio = ApiClient().dio;

  Future<void> _closeSession() async {
      if (_isClosing) return;
      final sessionId = widget.session['id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có ID phiên để đóng')),
          );
        }
        return;
      }

      setState(() => _isClosing = true);
      _timer?.cancel();

      try {
        // Sử dụng PUT để cập nhật status (backend của bạn dùng PUT)
        final response = await dio.put(
          "${AppConfig.teacherCloseSession}/$sessionId/close",
          options: Options(headers: {'Accept': 'application/json'}),
        );

        final code = response.statusCode ?? 0;
        if (code == 200 || code == 204) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã kết thúc phiên trên server')),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể đóng phiên (code: $code)')),
            );
          }
          print('Close session failed: $code ${response.data}');
        }
      } on DioError catch (e) {
        if (mounted) {
          final msg = e.response != null
              ? 'Lỗi server: ${e.response?.statusCode}'
              : 'Lỗi mạng: ${e.message}';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
        print('DioError closing session: $e');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
        print('Exception closing session: $e');
      } finally {
        if (mounted) setState(() => _isClosing = false);
      }
    }



  @override
  void initState() {
    super.initState();
    print("--- MÀN HÌNH QR INIT ---"); // Lệnh debug

    // Prefer deep_link if server provided it (full URL), otherwise build a stable payload.
    // Use full deep_link so student scanner can parse ?token=... reliably.
    final tokenVal = widget.session['token']?.toString();
    final deepLink = widget.session['deep_link']?.toString();
    if (deepLink != null && deepLink.isNotEmpty) {
      qrData = deepLink;
    } else if (tokenVal != null && tokenVal.isNotEmpty) {
      // Use a stable prefix so scanner code can recognise token strings if needed
      qrData = 'attendance_token_$tokenVal';
    } else {
      qrData = widget.session['id']?.toString() ?? '';
    }


    // Phân tích thời gian
    _startTime = DateTime.tryParse(widget.session['start_at'] ?? '');
    _endTime = DateTime.tryParse(widget.session['end_at'] ?? '');

    // --- DEBUG ---
    // ✅ Kiểm tra xem dữ liệu thời gian nhận vào có đúng không
    print("start_at (raw): ${widget.session['start_at']}");
    print("end_at (raw): ${widget.session['end_at']}");
    print("Parsed _startTime: $_startTime");
    print("Parsed _endTime: $_endTime");
    // --- /DEBUG ---

    // Nếu không có thời gian hợp lệ, dừng lại và báo lỗi
    if (_startTime == null || _endTime == null) {
      print("LỖI: Thời gian start/end là null hoặc không hợp lệ. Timer SẼ KHÔNG chạy.");
      setState(() {
        _statusMessage = "Lỗi: Thời gian không hợp lệ";
        remainingSeconds = 0;
      });
      return; // Quan trọng: Thoát ra
    }

    print("Thời gian hợp lệ. Đang bắt đầu timer...");

    // Cập nhật thời gian lần đầu tiên
    _updateRemainingTime();

    // Bắt đầu timer và gọi hàm cập nhật mỗi giây
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  /// ✅ THAY ĐỔI 2: Cập nhật hàm này để xử lý 3 trạng thái
  void _updateRemainingTime() {
    // Nếu không có thời gian, dừng lại
    if (_startTime == null || _endTime == null) {
      _timer?.cancel();
      return;
    }

    final now = DateTime.now();

    if (now.isBefore(_startTime!)) {
      // --- TRƯỜNG HỢP 1: Phiên chưa bắt đầu ---
      final diff = _startTime!.difference(now).inSeconds;
      setState(() {
        _statusMessage = "Sắp bắt đầu sau:"; // Thay đổi 1
        // Hiển thị đếm ngược TỚI LÚC BẮT ĐẦU
        remainingSeconds = diff > 0 ? diff : 0;
      });

    } else if (now.isAfter(_endTime!)) {
      // --- TRƯỜNG HỢP 3: Phiên đã kết thúc ---
      setState(() {
        _statusMessage = "Phiên đã kết thúc"; // Thay đổi 2
        remainingSeconds = 0;
      });
      _timer?.cancel();

      // Hiển thị thông báo và đóng trang
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phiên điểm danh đã kết thúc!')),
        );
        Navigator.pop(context);
      }

    } else {
      // --- TRƯỜNG HỢP 2: Phiên đang diễn ra (logic đếm ngược) ---
      final diff = _endTime!.difference(now).inSeconds;
      setState(() {
        _statusMessage = "Thời gian còn lại:"; // Thay đổi 3
        // Hiển thị đếm ngược TỚI LÚC KẾT THÚC
        remainingSeconds = diff > 0 ? diff : 0;
      });
    }
  }

  @override
  void dispose() {
    print("--- MÀN HÌNH QR DISPOSE ---"); // Lệnh debug
    _timer?.cancel();
    super.dispose();
  }

  // Hàm format thời gian (Bạn đã có)
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
                  // ✅ THAY ĐỔI 3: Sử dụng _statusMessage và hàm formatDuration
                  child: Text(
                    "$_statusMessage ${formatDuration(remainingSeconds)}",
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
                Text("Phòng học: ${session['room'] ?? '—'}"),
                const SizedBox(height: 8),
                Text("Lớp học: ${session['class_name'] ?? '—'}"),
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
                  onPressed: _isClosing
                      ? null
                      : () async {
                          await _closeSession();
                        },
                  label: _isClosing
                      ? const Text(
                          "Đang kết thúc...",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        )
                      : const Text(
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
