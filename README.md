## đây là cài cho php
-vì máy chủ ảo đã hết thười hạn sử dụng nên chúng ta tạm thời tự chạy bằng local\
-chạy tạo toàn bộ CSDL trên file CSDL_xinhon.sql\
-khi clone về chúng ta phải vào folder chưa code laravel và chạy composer install\
-sau đó đổi cái .env csdl theo tên mà chúng mày đặt\
-vẫn trong laravel đó và chạy :\
-php artisan key:generate\
-php artisan tinker\
-App\Models\User::where('password', '1')->update(['password' => \Illuminate\Support\Facades\Hash::make('1')]);\
-php artisan migrate --path=database/migrations/2025_11_01_123456_create_ten_bang_cache_cua_ban.php (thay bằng tên cái bằng cache có sẵn trong thư mục database/migrations)\
-dòng 141 142 file StudentController.php hãy bỏ cmt dòng địa chỉ local ra và cmt dòng địa chỉ ip ảo lại vì mình chạy local\

## đây là cài cho python
-recommend cài python 3.12.10 hoặc thập hơn chút\
-pip install flask deepface\
-Nhấn nút Start (hoặc phím Windows), gõ regedit và mở Registry Editor.\
-Ở thanh địa chỉ trên cùng, dán đường dẫn này vào và nhấn Enter: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\
-Ở cửa sổ bên phải, tìm một giá trị tên là LongPathsEnabled.\
-Kích đúp chuột vào LongPathsEnabled và đổi giá trị (Value data) của nó từ 0 thành 1.\
-Nhấn OK và đóng Registry Editor.\
-Khởi động lại máy tính (hoặc ít nhất là khởi động lại hoàn toàn cửa sổ terminal của bạn).\
-Chạy lại lệnh pip install ... của bạn.\
-pip install tf-keras\
-python match_server.py\

## đây là cài trong Android Studio
-trong config.dart bỏ cmt dòng ip local ra và cmt dòng ip ảo ngoài lại\

## hiện tại t mới nhớ cài có thế nếu xong mà không chạy được thì mở miệng ra nói :)))))
