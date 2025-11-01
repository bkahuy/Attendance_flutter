import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';

class StudentCheckinPage extends StatefulWidget {
  final Map<String, dynamic> session;
  final File photo;
  const StudentCheckinPage({super.key, required this.session,required this.photo,});

  @override
  State<StudentCheckinPage> createState() => _StudentCheckinPageState();
}

class _StudentCheckinPageState extends State<StudentCheckinPage> {
  String? status;
  String password = '';
  File? photo;
  bool sending = false;

  Future<void> _pickPhoto() async {
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
    // Gán ảnh đã chụp
    photo = widget.photo;
    // Đặt locale để format ngày (ví dụ: "Th 6")
    Intl.defaultLocale = 'vi_VN';
  }

  Future<void> _submit() async {
    if (status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trạng thái điểm danh')),
      );
      return;
    }

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

    setState(() => sending = true);
    try {
      // 🎨 SỬA LỖI (từ lần trước):
      // Đảm bảo 'session_id' được kiểm tra null và parse an toàn
      final dynamic sessionId = widget.session['session_id'];
      if (sessionId == null) {
        throw Exception("Không tìm thấy ID buổi học (session_id is null).");
      }
      final int sessionIdAsInt = int.parse(sessionId.toString());

      // 🎨 GHI CHÚ DEBUG (từ lần trước):
      // Thêm print để kiểm tra lỗi 422
      print("===== DỮ LIỆU GỬI ĐI (checkIn): =====");
      print("sessionId: $sessionIdAsInt");
      print("status: $statusValue");
      print("password: $password");
      print("photoFile exists: ${photo != null}");
      print("====================================");

      await AttendanceService().checkIn(
        sessionId: sessionIdAsInt,
        status: statusValue,
        password: password.isEmpty ? null : password,
        photoFile: photo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm danh thành công!')),
      );

      // Quay về trang trước đó
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi điểm danh: $e')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }


  // 🎨 CẬP NHẬT: Dùng Row thay vì ListTile để có giao diện gọn (giống ảnh)
  Widget _buildRadioOption(String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          status = title;
        });
      },
      // Bọc trong Row để radio và text sát nhau
      child: Row(
        mainAxisSize: MainAxisSize.min, // Giữ cho Row co lại
        children: [
          Radio<String>(
            value: title,
            groupValue: status,
            onChanged: (String? value) {
              setState(() {
                status = value;
              });
            },
            // Giảm padding mặc định của Radio
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final className = s['class_name'] ?? 'Lớp';
    final courseName = s['course_name'] ?? 'Tên môn học';
    // final courseCode = s['course_code'] ?? 'Mã môn'; // 🎨 BỎ (không có trong ảnh)

    // 🎨 CẬP NHẬT: Dùng tryParse để an toàn hơn
    final sessionDate = DateTime.tryParse(s['date'] ?? '') ?? DateTime.now();

    // 🎨 CẬP NHẬT: Format "Thứ... dd/MM/yyyy"
    // (Ảnh dùng "Fri" là tiếng Anh, ta dùng "vi_VN" sẽ ra "T6" hoặc "Thứ 6")
    final formattedDate = DateFormat("E dd/MM/yyyy", "vi_VN").format(sessionDate);
    final photoName = photo == null ? '' : photo!.path.split('/').last;

    return Scaffold(
      // 🎨 CẬP NHẬT: AppBar
      appBar: AppBar(
        leading: const BackButton(color: Colors.white), // Icon back màu trắng
        title: const Text(
          'Máy ảnh', // Đổi tiêu đề
          style: TextStyle(color: Colors.white), // Chữ màu trắng
        ),
        backgroundColor: Colors.indigo.shade400, // Nền màu tím
        elevation: 1, // Thêm bóng mờ
      ),

      // 🎨 CẬP NHẬT: Nền
      backgroundColor: Colors.white,

      // 🔹 Nội dung chính
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),

        // 🎨 CẬP NHẬT: Card
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100], // Màu xám rất nhạt
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎨 CẬP NHẬT: Thứ tự (Lớp -> Tên môn)
                Text(
                  'Lớp $className',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  courseName, // 🎨 Bỏ courseCode
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 16),

                // 🎨 CẬP NHẬT: Hàng ngày tháng và tên ảnh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ngày tháng
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                    const SizedBox(width: 16),
                    // Tên ảnh (Bỏ IconButton)
                    Flexible(
                      child: Text(
                        photoName,
                        style:
                        TextStyle(fontSize: 14, color: Colors.grey[800]),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 🎨 CẬP NHẬT: Dùng widget _buildRadioOption đã sửa
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

                // 🎨 CẬP NHẬT: Căn lề nút "XÁC NHẬN" sang phải
                Align(
                  alignment: Alignment.centerRight,
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