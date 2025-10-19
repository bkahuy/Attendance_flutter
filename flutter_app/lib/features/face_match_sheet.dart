import 'package:flutter/material.dart';
import '../../api/face_api.dart';

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

    // TODO: TÍCH HỢP SDK REGULA Ở ĐÂY
    // 1) Mở camera + liveness
    // 2) Nhận similarity/decision từ SDK (giả lập):
    final double similarity = 0.84; // giả lập
    final double threshold  = 0.75; // lấy từ mode_flags của session nếu muốn
    final String decision   = similarity >= threshold ? 'accept' : 'reject';

    try {
      final matchId = await FaceApi().logMatch(
        attendanceSessionId: widget.attendanceSessionId,
        studentId: widget.studentId,
        similarity: similarity,
        threshold: threshold,
        decision: decision,
        method: '1:1',
        livenessType: 'passive',
        livenessScore: 0.98,
      );
      setState(() { _status = 'Match=$decision (id=$matchId, s=$similarity)'; });

      if (decision == 'accept') {
        // GỌI API check-in cũ của bạn (giữ ảnh + GPS như hiện tại)
        // await AttendanceRepository().checkIn(...);
        // Hiển thị done:
        if (mounted) Navigator.pop(context, true);
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
