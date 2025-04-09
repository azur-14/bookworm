class Book {
  final String id;
  String title;
  String author;
  String publisher;
  String publishYear;
  String categoryId; // Lưu category id thay vì tên
  String status;
  DateTime timeCreate;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.publishYear,
    required this.categoryId,
    required this.status,
    required this.timeCreate,
  });

  factory Book.fromMap(Map<String, dynamic> data) {
    return Book(
      id: data['id'] as String,
      title: data['title'] as String,
      author: data['author'] as String,
      publisher: data['publisher'] as String,
      publishYear: data['publishYear'] as String,
      categoryId: data['categoryId'] as String,
      status: data['status'] as String,
      timeCreate: DateTime.parse(data['timeCreate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publisher': publisher,
      'publishYear': publishYear,
      'categoryId': categoryId,
      'status': status,
      'timeCreate': timeCreate.toIso8601String(),
    };
  }
}
