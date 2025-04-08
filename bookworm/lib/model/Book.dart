class Book {
  final String id;
  final String name;
  final String type;
  final String language;
  final String availability;

  Book({
    required this.id,
    required this.name,
    required this.type,
    required this.language,
    required this.availability,
  });

  // Optional: fromMap and toMap methods for JSON conversion if needed
  factory Book.fromMap(Map<String, dynamic> data) {
    return Book(
      id: data['id'] as String,
      name: data['name'] as String,
      type: data['type'] as String,
      language: data['language'] as String,
      availability: data['availability'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'language': language,
      'availability': availability,
    };
  }
}
