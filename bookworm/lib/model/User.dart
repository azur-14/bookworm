
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

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['_id'] ?? json['id'], // MongoDB dùng _id
    avatar: json['avatar'] ?? '',
    email: json['email'],
    password: json['password'],
    role: json['role'],
    status: json['status'],
    name: json['name'],
    phone: json['phone'] ?? '',
    timeCreate: DateTime.parse(json['timeCreate']),
  );

  Map<String, dynamic> toJson() => {
    'avatar': avatar,
    'email': email,
    'password': password,
    'role': role,
    'status': status,
    'name': name,
    'phone': phone,
    'timeCreate': timeCreate.toIso8601String(),
  };
}
