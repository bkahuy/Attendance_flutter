## Hệ thống điểm danh sinh viên bằng nhận diện khuôn mặt

Hệ thống được xây dựng nhằm hỗ trợ quản lý và thực hiện điểm danh sinh viên một cách tự động, chính xác và thuận tiện thông qua công nghệ nhận diện khuôn mặt. Dự án bao gồm ứng dụng di động dành cho giảng viên và sinh viên được phát triển bằng Flutter, hệ thống quản trị dành cho bộ phận quản lý được xây dựng bằng Laravel Blade, cùng với backend RESTful API sử dụng Laravel để phục vụ đồng thời cho cả nền tảng web và mobile.

Ứng dụng cho phép giảng viên tạo các buổi điểm danh theo từng tiết học, theo dõi danh sách sinh viên tham gia và quản lý kết quả điểm danh. Sinh viên có thể thực hiện check-in trực tiếp trên ứng dụng di động thông qua công nghệ nhận diện khuôn mặt. Ngoài ra, hệ thống còn tích hợp chức năng quét mã QR để truy cập nhanh vào buổi điểm danh, giúp tối ưu thời gian và nâng cao trải nghiệm sử dụng.

Đối với bộ phận quản lý, hệ thống web admin cung cấp các chức năng quản lý lịch học, phân công phòng học, theo dõi dữ liệu điểm danh theo thời gian thực và thống kê tình hình chuyên cần của sinh viên.

### Chức năng chính

* Quản lý tài khoản sinh viên, giảng viên và quản trị viên.
* Tạo và quản lý lịch học, lớp học và phòng học.
* Giảng viên tạo buổi điểm danh theo từng tiết học.
* Sinh viên điểm danh bằng công nghệ nhận diện khuôn mặt trên ứng dụng di động.
* Tích hợp quét mã QR để truy cập nhanh vào buổi điểm danh.
* Theo dõi và quản lý dữ liệu điểm danh theo thời gian thực.
* Thống kê và báo cáo kết quả điểm danh.

### Công nghệ sử dụng

* **Mobile:** Flutter (Dart)
* **Web Admin:** Laravel Blade
* **Backend:** Laravel RESTful API
* **Cơ sở dữ liệu:** MySQL
* **Nhận diện khuôn mặt:** Python, DeepFace
* **Xác thực người dùng:** JWT, Laravel Authentication

### Triển khai hệ thống

Hệ thống được thiết kế theo mô hình client-server với kiến trúc RESTful API. Cơ sở dữ liệu MySQL được xây dựng bao gồm các thực thể chính như Sinh viên, Giảng viên, Quản trị viên, Lớp học, Lịch học, Buổi điểm danh và Kết quả điểm danh cùng các bảng liên quan khác.

Backend Laravel đảm nhiệm việc xử lý nghiệp vụ, xác thực người dùng, quản lý lịch học và điểm danh, đồng thời cung cấp các API cho ứng dụng di động và hệ thống quản trị. Mô hình nhận diện khuôn mặt được xây dựng bằng DeepFace trên nền tảng Python nhằm xác minh danh tính sinh viên trước khi thực hiện điểm danh, góp phần hạn chế tình trạng điểm danh hộ và nâng cao độ chính xác của hệ thống.
