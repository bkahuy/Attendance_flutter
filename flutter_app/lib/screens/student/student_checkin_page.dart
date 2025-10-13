import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/attendance_service.dart';

class StudentCheckinPage extends StatefulWidget {
  final Map<String, dynamic> session;
  const StudentCheckinPage({super.key, required this.session});

  @override
  State<StudentCheckinPage> createState() => _StudentCheckinPageState();
}

class _StudentCheckinPageState extends State<StudentCheckinPage> {
  String status = 'present';
  String password = '';
  File? photo;
  Position? pos;
  bool sending = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 85);
    if (img != null) setState(() => photo = File(img.path));
  }

  Future<void> _getLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) { await Geolocator.openLocationSettings(); return; }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có quyền GPS')));
      return;
    }
    final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => pos = p);
  }

  Future<void> _submit() async {
    setState(() => sending = true);
    try {
      await AttendanceService().checkIn(
        sessionId: widget.session['session_id'] as int,
        status: status,
        password: password.isEmpty ? null : password,
        lat: pos?.latitude,
        lng: pos?.longitude,
        photoFile: photo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điểm danh thành công!')));
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi điểm danh: $e')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận điểm danh')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Môn: ${s['course'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Thời gian: ${s['start_at']} - ${s['end_at']}'),
          const SizedBox(height: 12),

          const Text('Trạng thái'),
          DropdownButton<String>(
            value: status,
            items: const [
              DropdownMenuItem(value: 'present', child: Text('Có mặt')),
              DropdownMenuItem(value: 'late', child: Text('Muộn')),
              DropdownMenuItem(value: 'absent', child: Text('Vắng')),
            ],
            onChanged: (v) => setState(() => status = v!),
          ),

          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Password (nếu giảng viên yêu cầu)'),
            onChanged: (v) => password = v,
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Chụp ảnh'),
              ),
              const SizedBox(width: 8),
              if (photo != null) const Icon(Icons.check_circle, color: Colors.green),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Lấy GPS'),
              ),
              const SizedBox(width: 8),
              if (pos != null) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: sending ? null : _submit,
            child: sending ? const CircularProgressIndicator() : const Text('Xác nhận điểm danh'),
          ),
        ],
      ),
    );
  }
}
