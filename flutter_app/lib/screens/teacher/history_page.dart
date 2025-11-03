import 'package:flutter/material.dart';
import 'detail_page.dart';
import '../../services/attendance_service.dart'; // (Đường dẫn service của bạn)
import '../../models/attendance_history.dart'; // (Đường dẫn model của bạn)

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Đặt index = 1 để icon "Clock" được chọn
  int _selectedIndex = 1;


  final AttendanceService apiService = AttendanceService();

  // 1. Controllers để lấy text từ các ô tìm kiếm
  final _courseNameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _starttimeController = TextEditingController();

  // 2. Trạng thái tải và danh sách kết quả
  bool _isLoading = false;
  bool _hasSearched = false; // Cờ để biết người dùng đã tìm kiếm hay chưa
  List<AttendanceHistory> _searchResults = [];

  // === HÀM TÌM KIẾM ===
  Future<void> _performSearch() async {

    setState(() {
      _isLoading = true;
      _hasSearched = true; // Đánh dấu là đã tìm kiếm
      _searchResults = []; // Xóa kết quả cũ
    });

    try {
      final results = await apiService.getAttendanceHistory(
        courseName: _courseNameController.text,
        className: _classNameController.text,
        room: _locationController.text,
        startTime: _starttimeController.text,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      // Xử lý lỗi (ví dụ: hiển thị SnackBar)
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tìm kiếm: $e')),
      );
    }
  }

  // === HÀM XỬ LÝ NHẤN BOTTOM BAR ===
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Thêm logic điều hướng cho các tab khác ở đây (nếu cần)
  }



  // === HÀM BUILD CHÍNH ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // --- BODY VỚI LOGIC TÌM KIẾM (Giữ nguyên) ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tìm kiếm lịch sử',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 1. FORM TÌM KIẾM
            _buildSearchForm(),

            const SizedBox(height: 16),

            // 2. NÚT TÌM KIẾM
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performSearch, // Gọi hàm tìm kiếm
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text(''
                    'Tìm kiếm',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent, // Màu tím đậm
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const Divider(height: 32),

            // 3. KHU VỰC HIỂN THỊ KẾT QUẢ
            _buildResultsList(),
          ],
        ),
      ),

    );
  }

  // === WIDGET CHO FORM TÌM KIẾM (Giữ nguyên) ===
  Widget _buildSearchForm() {
    return Column(
      children: [
        _buildSearchTextField(
          controller: _courseNameController,
          hintText: 'Nhập tên môn học',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 16),
        _buildSearchTextField(
          controller: _classNameController,
          hintText: 'Nhập tên lớp',
          icon: Icons.group_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSearchTextField(
                controller: _locationController,
                hintText: 'Phòng',
                icon: Icons.location_on_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSearchTextField(
                controller: _starttimeController,
                hintText: 'Giờ (HH:mm:ss)',
                icon: Icons.access_time_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // === WIDGET HIỂN THỊ KẾT QUẢ (Giữ nguyên) ===
  Widget _buildResultsList() {
    // 1. Nếu đang tải
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Nếu chưa tìm kiếm
    if (!_hasSearched) {
      return const Center(
        child: Text('Vui lòng nhập thông tin và nhấn tìm kiếm.'),
      );
    }

    // 3. Nếu đã tìm kiếm nhưng không có kết quả
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả nào.'),
      );
    }

    // 4. Nếu có kết quả
    return ListView.builder(
      itemCount: _searchResults.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final session = _searchResults[index];
        // Sử dụng lại hàm _buildHistoryCard với dữ liệu mới
        return _buildHistoryCard(context, session);
      },
    );
  }

  // === WIDGET HỖ TRỢ TẠO Ô TÌM KIẾM (Giữ nguyên) ===
  Widget _buildSearchTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  // === HÀM _buildHistoryCard (Giữ nguyên) ===
  Widget _buildHistoryCard(BuildContext context, AttendanceHistory session) {
    return Card(
      // elevation: 1,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          print("Đang bấm vào session với ID: ${session.sessionId}");
          final String sessionId = session.sessionId.toString();
          final String courseName = session.courseName;
          if (sessionId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(
                  courseTitle: courseName,
                  sessionId: sessionId,
                ),
              ),
            );
          } else {
            // Xử lý trường hợp ID không hợp lệ
            print("Lỗi: Không thể mở trang chi tiết vì session ID không hợp lệ.");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể tải chi tiết phiên. Vui lòng thử lại.')),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.courseName, // Dữ liệu từ API
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.className, // Dữ liệu từ API
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(

                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          session.room, // Dữ liệu từ API
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                session.startTime, // Dữ liệu từ API
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === HÀM dispose (Giữ nguyên) ===
  @override
  void dispose() {
    _courseNameController.dispose();
    _classNameController.dispose();
    _locationController.dispose();
    _starttimeController.dispose();
    super.dispose();
  }
}