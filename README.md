Final SOA - Ứng dụng quản lí thư viện

Ứng dụng được xây dựng theo kiến trúc Microservice, sử dụng:

- Flutter cho frontend.
- Node.js (Express) cho backend.
- MongoDB Atlas cho cơ sở dữ liệu.

---
Tài khoản khách hàng: 
hieungan0906@gmail.com
123456

Tài khoản thủ thư:
lethihieungan04@gmail.com
123456

Tài khoản quản trị viên: 
azurahope14@gmail.com
123456

1. ⚙️ Yêu cầu hệ thống

- [Node.js](https://nodejs.org/) v14+
- [Flutter SDK](https://flutter.dev/)
- Thiết bị ảo hoặc thật để chạy app Flutter
- Kết nối internet (để truy cập MongoDB Atlas)

2.🚀 Hướng dẫn chạy ứng dụng

a. Bước 1: Cài đặt backend

Đi tới thư mục chứa các service: cd service và chạy: 

npm install express mongoose body-parser cors dotenv uuid axios bcrypt jsonwebtoken nodemailer moment swagger-jsdoc swagger-ui-express

b.Bước 2: Cấu hình MongoDB

Mỗi service đã được cấu hình sẵn file .env,
Bạn không cần cài MongoDB nếu kết nối này vẫn hoạt động. Các service sẽ tự kết nối đến MongoDB Atlas.

c. Bước 3: Khởi động các service

Chạy từng service trong các tab terminal riêng biệt: node server.js


d. Bước 4: Chạy ứng dụng Flutter

Đi tới thư mục Flutter app:
flutter pub get
flutter run

