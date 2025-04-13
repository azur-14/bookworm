
/// Model User – không có trường username, avatar là chuỗi base64 (không bắt buộc)
class User {
  String id;
  String avatar; // Chứa chuỗi base64 nếu có chọn avatar, còn không thì rỗng
  String password;
  String role;
  String status;
  String name;
  String email;
  String phone;
  DateTime timeCreate;

  User({
    required this.id,
    this.avatar = '',
    required this.password,
    required this.role,
    required this.status,
    required this.name,
    required this.email,
    required this.phone,
    required this.timeCreate,
  });
}
