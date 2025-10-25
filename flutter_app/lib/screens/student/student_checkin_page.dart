import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // Import thư viện intl
import '../../services/attendance_service.dart';

class StudentCheckinPage extends StatefulWidget {
  final Map<String, dynamic> session;
  const StudentCheckinPage({super.key, required this.session});

  @override
  State<StudentCheckinPage> createState() => _StudentCheckinPageState();
}

class _StudentCheckinPageState extends State<StudentCheckinPage> {
  // Đổi status từ Dropdown thành Radio button
  // Giá trị có thể là 'Có mặt', 'Muộn', 'Vắng'
  String? status;
  String password = '';
  File? photo;
  Position? pos;
  bool sending = false;

  Future<void> _pickPhoto() async {
    // Chức năng chụp ảnh vẫn được giữ lại để sử dụng ở logic nền
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 85,preferredCameraDevice: CameraDevice.front,);
    if (img != null) {
      setState(() {
        photo = File(img.path);
      });
    }
  }
  @override
  void initState() {
    super.initState();
    // Nếu đã có ảnh truyền sẵn từ CourseDetailPage, gán luôn
    if (widget.session['photo_path'] != null) {
      photo = File(widget.session['photo_path']);
    }
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
    if (status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trạng thái điểm danh')),
      );
      return;
    }

    // Ánh xạ lại giá trị để gửi đi
    String statusValue;
    switch (status) {
      case 'Có mặt':
        statusValue = 'present';
        break;
      case 'Muộn':
        statusValue = 'late';
        break;
      case 'Vắng':
        statusValue = 'absent';
        break;
      default:
        statusValue = 'present';
    }

    // 👉 Chỉ chụp ảnh nếu chưa có
    if (photo == null) {
      await _pickPhoto();
      if (photo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa chụp ảnh xác nhận')),
        );
        return;
      }
    }

    await _getLocation();

    setState(() => sending = true);
    try {
      await AttendanceService().checkIn(
        sessionId: widget.session['session_id'] as int,
        status: statusValue,
        password: password.isEmpty ? null : password,
        lat: pos?.latitude,
        lng: pos?.longitude,
        photoFile: photo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm danh thành công!')),
      );

      // ✅ Trở về trang chi tiết môn học và cập nhật trạng thái
      Navigator.of(context).pop({
        'checkedIn': true,
        'status': statusValue,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi điểm danh: $e')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }



  // Widget riêng cho các lựa chọn Radio
  Widget _buildRadioOption(String title) {
    return ListTile(
      title: Text(title),
      leading: Radio<String>(
        value: title,
        groupValue: status,
        onChanged: (String? value) {
          setState(() {
            status = value;
          });
        },
      ),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        setState(() {
          status = title;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final className = s['class_name'] ?? 'Lớp';
    final courseName = s['course_name'] ?? 'Tên môn học';
    final courseCode = s['course_code'] ?? 'Mã môn';
    final sessionDate = DateTime.parse(s['date']);
    final formattedDate = DateFormat("E dd/MM/yyyy", "vi_VN").format(sessionDate);
    final photoName = photo == null ? '' : photo!.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        // Thêm nút Back (quay lại trang CourseDetail)
        leading: const BackButton(color: Colors.black),
        // Đổi tiêu đề cho rõ ràng hơn
        title: const Text(
          'Xác nhận điểm danh',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // 🔹 Nội dung chính
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: const Color(0xFFE0E0E0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lớp $className',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$courseCode $courseName',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ngày tháng
                    Flexible(
                      flex: 3,
                      child: Text(
                        formattedDate,
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tên ảnh và Nút chụp lại
                    Flexible(
                      flex: 4, // Cho nhiều không gian hơn
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Đẩy sang phải
                        children: [
                          // Tên file (linh hoạt)
                          Flexible(
                            child: Text(
                              photoName,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[800]),
                              overflow: TextOverflow.ellipsis, // Chống tràn text
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // Nút "Quay lại Camera" (Chụp lại)
                          IconButton(
                            icon: const Icon(Icons.camera_alt_outlined),
                            color: Colors.grey[900],
                            tooltip: 'Chụp lại',
                            onPressed: _pickPhoto, // Gọi lại hàm chụp ảnh
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _buildRadioOption('Có mặt'),
                _buildRadioOption('Muộn'),
                _buildRadioOption('Vắng'),

                const SizedBox(height: 16),
                const Text(
                  'Password:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  onChanged: (v) => password = v,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: sending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: sending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text(
                      'XÁC NHẬN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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