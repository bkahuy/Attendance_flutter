import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../api/student_repository.dart';
import '../../widgets/primary_button.dart';

class CheckInScreen extends StatefulWidget {
  final int sessionId;
  const CheckInScreen({super.key, required this.sessionId});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _repo = StudentRepository();
  File? _photo;
  String _status = 'present';
  String _pwd = '';
  bool _loading = false;
  double? _lat, _lng;
  Future<void> _pickPhoto() async {
    final im = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (im != null) setState(() => _photo = File(im.path));
  }

  Future<void> _getLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition();
    setState(() => {_lat = pos.latitude, _lng = pos.longitude});
  }

  Future<void> _submit() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chụp ảnh trước đã')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _repo.checkIn(
          sessionId: widget.sessionId,
          status: _status,
          photoFile: _photo,
          lat: _lat,
          lng: _lng,
          password: _pwd.isEmpty ? null : _pwd);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('OK: ${res['message']}')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Điểm danh (Session #${widget.sessionId})')),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(children: [
              Row(children: [
                ElevatedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh')),
                const SizedBox(width: 12),
                if (_photo != null)
                  const Icon(Icons.check, color: Colors.green),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'present', child: Text('Có mặt')),
                    DropdownMenuItem(value: 'late', child: Text('Muộn')),
                    DropdownMenuItem(value: 'absent', child: Text('Vắng')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'present'),
                  decoration: const InputDecoration(labelText: 'Trạng thái')),
              const SizedBox(height: 8),
              TextField(
                  onChanged: (v) => _pwd = v,
                  decoration: const InputDecoration(
                      labelText: 'Password (nếu GV yêu cầu)')),
              const SizedBox(height: 8),
              Row(children: [
                OutlinedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Lấy GPS')),
                const SizedBox(width: 12),
                Text(_lat == null ? 'Chưa lấy GPS' : '\${_lat},\${_lng}'),
              ]),
              const SizedBox(height: 16),
              PrimaryButton(text: 'Gửi', onPressed: _submit, loading: _loading),
            ])));
  }
}
