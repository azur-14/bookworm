class Book {
  final String id;
  String image;
  String title;
  String author;
  String publisher;
  int publishYear;
  double price;             // ⭐ THÊM dòng này
  String categoryId;
  int totalQuantity;
  int availableQuantity;
  String? description;
  DateTime timeCreate;

  Book({
    required this.id,
    this.image = '',
    required this.title,
    required this.author,
    required this.publisher,
    required this.publishYear,
    required this.price,           // ⭐ THÊM required price
    required this.categoryId,
    required this.totalQuantity,
    required this.availableQuantity,
    this.description,
    required this.timeCreate,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      image: json['image'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      publishYear: (json['publish_year'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // ⭐ THÊM dòng này
      categoryId: json['category_id'] as String? ?? '',
      totalQuantity: (json['total_quantity'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['available_quantity'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      timeCreate: DateTime.parse(json['timeCreate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'title': title,
      'author': author,
      'publisher': publisher,
      'publish_year': publishYear,
      'price': price,                        // ⭐ THÊM dòng này
      'category_id': categoryId,
      'total_quantity': totalQuantity,
      'available_quantity': availableQuantity,
      'description': description,
      'timeCreate': timeCreate.toIso8601String(),
    };
  }
}
