// model/BookItem.dart
class BookItem {
  final int id;
  int bookId;
  int? shelfId;        // quan hệ tới Shelf.id
  String shelfName;    // hoặc fetch riêng
  String status;       // available, borrowed, damaged, lost
  String? damageImage; // URL hoặc base64 khi hỏng
  DateTime timeCreate;

  BookItem({
    required this.id,
    required this.bookId,
    this.shelfId,
    this.shelfName = '',
    required this.status,
    this.damageImage,
    required this.timeCreate,
  });

  factory BookItem.fromJson(Map<String, dynamic> json) {
    return BookItem(
      id: json['id'] as int,
      bookId: (json['book_id'] as num).toInt(),
      shelfId: (json['shelf_id'] as num?)?.toInt(),
      shelfName: json['shelf_name'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      damageImage: json['damage_image'] as String?,
      timeCreate: DateTime.parse(json['timeCreate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'shelf_id': shelfId,
      'status': status,
      'damage_image': damageImage,
      'timeCreate': timeCreate.toIso8601String(),
    };
  }
}
