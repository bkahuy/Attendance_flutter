import 'dart:io';
import 'dart:convert'; // 🎨 1. Thêm import để dùng Base64
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';
import 'student_home.dart';

class StudentCheckinPage extends StatefulWidget {
  final Map<String, dynamic> session;
  final File photo; // 👈 Tấm ảnh này là TỪ BƯỚC TRƯỚC (FaceScanPage)
  const StudentCheckinPage({super.key, required this.session,required this.photo,});

  @override
  State<StudentCheckinPage> createState() => _StudentCheckinPageState();
}

class _StudentCheckinPageState extends State<StudentCheckinPage> {
  String? status;
  String password = '';
  bool sending = false;

  // 🎨 2. Sửa State
  File? _previewPhoto; // Ảnh để xem
  String? _templateBase64; // Template để gửi đi

  // (Hàm _pickPhoto đã bị xóa vì không cần nữa)

  @override
  void initState() {
    super.initState();
    // 🎨 3. Dùng ảnh đã chụp ở bước trước
    _setInitialPhoto(widget.photo);
    Intl.defaultLocale = 'vi_VN';
  }

  // 🎨 4. Hàm mới: Chuyển File ảnh (từ FaceScanPage) sang Base64
  Future<void> _setInitialPhoto(File photoFile) async {
    // ‼️ TODO: TẠM THỜI (DÙNG CHO TEST)
    // Chúng ta đang gửi Base64 của ảnh thô.
    // BẠN NÊN thay thế logic này bằng SDK (như Regula)
    // để tạo "template" AI thực sự.
    final bytes = await photoFile.readAsBytes();
    final String base64String = base64Encode(bytes);

    setState(() {
      _previewPhoto = photoFile; // Lưu ảnh để xem
      _templateBase64 = base64String; // Lưu template để gửi
    });
  }

  // 🎨 5. SỬA HÀM SUBMIT
  Future<void> _submit() async {
    if (status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trạng thái điểm danh')),
      );
      return;
    }

    // 5a. Kiểm tra template
    if (_templateBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ảnh. Vui lòng thử lại.')),
      );
      return;
    }

    String statusValue;
    switch (status) {
      case 'Có mặt': statusValue = 'present'; break;
      case 'Muộn': statusValue = 'late'; break;
      case 'Vắng': statusValue = 'absent'; break;
      default: statusValue = 'absent';
    }

    setState(() => sending = true);
    try {
      final dynamic sessionId = widget.session['session_id'];
      if (sessionId == null) {
        throw Exception("Không tìm thấy ID buổi học (session_id is null).");
      }
      final int sessionIdAsInt = int.parse(sessionId.toString());

      // 5b. Gọi hàm checkIn đã sửa (trong AttendanceService)
      await AttendanceService().checkIn(
        sessionId: sessionIdAsInt,
        status: statusValue,
        templateBase64: _templateBase64!, // 👈 Gửi template
        password: password.isEmpty ? null : password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm danh thành công!')),
      );

      // 💡 SỬA LỖI ĐIỀU HƯỚNG: Pop an toàn bằng cách kiểm tra kiểu Widget.
      Navigator.of(context).popUntil(
              (route) {
            // 1. Nếu route là Route đầu tiên (root), dừng lại.
            if (route.isFirst) return true;

            // 2. Kiểm tra xem Route có đang build Widget StudentHome hay không.
            if (route is MaterialPageRoute) {
              return route.builder(context).runtimeType == StudentHome;
            }
            return false;
          }
      );

    } catch (e) {
// ... (xử lý lỗi)
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  // (Widget _buildRadioOption giữ nguyên)
  Widget _buildRadioOption(String title) {
    return GestureDetector(
      onTap: () { setState(() { status = title; }); },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: title,
            groupValue: status,
            onChanged: (String? value) { setState(() { status = value; }); },
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


    final classSection = (s['class_section'] is Map<String, dynamic>)
        ? s['class_section'] as Map<String, dynamic>
        : <String, dynamic>{}; // Map rỗng
    final courseName = classSection['course'] ?? '--'; // Key đúng là 'course'

// 3. Xử lý "className"
//    API của bạn KHÔNG trả về 'class_name'.
//    Có thể bạn muốn hiển thị 'term' (học kỳ) hoặc 'room' (phòng học)?
    final className = classSection['class_name'] ?? '--';
// hoặc
    final room = classSection['room'] ?? '--'; // 👈 TẠM DÙNG 'room'

    final sessionDate = DateTime.tryParse(s['date'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat("E dd/MM/yyyy", "vi_VN").format(sessionDate);

    // 🎨 6. Sửa Build
    // Lấy tên file từ _previewPhoto
    final photoName = _previewPhoto == null ? '' : _previewPhoto!.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Máy ảnh',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade400,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
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
                Text(
                  'Lớp $className',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  courseName,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 16),
                Text(
                  room,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        photoName, // 👈 Dùng photoName
                        style:
                        TextStyle(fontSize: 14, color: Colors.grey[800]),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
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

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: sending ? null : _submit, // 👈 Gọi hàm _submit đã sửa
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