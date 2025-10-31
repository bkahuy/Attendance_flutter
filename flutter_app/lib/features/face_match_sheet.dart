import 'package:flutter/material.dart';
import '../../api/face_api_service.dart';

class FaceMatchSheet extends StatefulWidget {
  final int attendanceSessionId;
  final int studentId; // đã có từ profile/login
  const FaceMatchSheet({super.key, required this.attendanceSessionId, required this.studentId});

  @override
  State<FaceMatchSheet> createState() => _FaceMatchSheetState();
}

class _FaceMatchSheetState extends State<FaceMatchSheet> {
  bool _loading = false;
  String? _status;

  Future<void> _runFaceMatch() async {
    setState(() { _loading = true; _status = null; });

    try {
      // 1) Mở UI liveness/capture của Regula (tên API có thể hơi khác theo version)
      //    Ví dụ khung:
      // final livenessResult = await regula.FaceSDK.startLiveness();
      // if (!(livenessResult?.success ?? false)) {
      //   setState(() { _status = 'Hủy hoặc fail liveness'; });
      //   return;
      // }
      // final bestShot = livenessResult.bestImage?.bitmap; // bytes ảnh khuôn mặt tốt nhất
      // final template = livenessResult.bestImage?.template; // embedding/template nếu SDK trả

      // 2) (Nếu bạn làm 1:1): gửi template lên backend để so sánh với mẫu đã enroll,
      //    hoặc dùng compare ngay trên thiết bị nếu SDK hỗ trợ.
      //    Ở đây mình giả sử backend trả về similarity.
      // double similarity = await FaceApiService().compareOnServer(templateBytes: template);

      // 2b) Tạm thời: nếu chưa viết compare server, dùng similarity mô phỏng
      double similarity = 0.84;

      // Ngưỡng quyết định (có thể lấy từ session/mode_flags)
      double threshold = 0.75;
      final decision = similarity >= threshold ? 'accept' : 'reject';

      // 3) Log lên server (để thầy/cô có audit)
      final matchId = await FaceApiService().logMatch(
        attendanceSessionId: widget.attendanceSessionId,
        studentId: widget.studentId,
        similarity: similarity,
        threshold: threshold,
        decision: decision,
      );

      setState(() {
        _status = decision == 'accept'
            ? '✅ Khớp khuôn mặt (matchId=$matchId)'
            : '❌ Không khớp (sim=${similarity.toStringAsFixed(2)})';
      });

      if (decision == 'accept' && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() { _status = 'Match lỗi: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Xác thực khuôn mặt để điểm danh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _runFaceMatch,
              child: _loading ? const CircularProgressIndicator() : const Text('Quét khuôn mặt'),
            ),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
