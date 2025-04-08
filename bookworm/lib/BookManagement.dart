import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model/book.dart'; // Ensure this file exists and contains your Book model

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({Key? key}) : super(key: key);

  @override
  _BookManagementPageState createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  late DateTime _currentTime;
  Timer? _timer;

  // Sample list of Book objects (replace with your actual data as needed)
  final List<Book> _books = [
    Book(
      id: '1',
      name: 'Hibernate Core - 11th',
      type: 'Educational',
      language: 'English',
      availability: 'Borrowed',
    ),
    Book(
      id: '2',
      name: 'Hibernate Core - 11th',
      type: 'Educational',
      language: 'English',
      availability: 'Available',
    ),
    Book(
      id: '3',
      name: 'Hibernate Core - 11th',
      type: 'Educational',
      language: 'English',
      availability: 'Borrowed',
    ),
    Book(
      id: '4',
      name: 'Hibernate Core - 11th',
      type: 'Educational',
      language: 'English',
      availability: 'Available',
    ),
    Book(
      id: '5',
      name: 'Hibernate Core - 11th',
      type: 'Educational',
      language: 'English',
      availability: 'Borrowed',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Update the time every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Build the DataTable using the list of Books.
  Widget buildBookDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Language')),
          DataColumn(label: Text('Availability')),
          DataColumn(label: Text('Action')),
        ],
        rows: _books.map((Book book) {
          return DataRow(
            cells: [
              DataCell(Text(book.id)),
              DataCell(Text(book.name)),
              DataCell(Text(book.type)),
              DataCell(Text(book.language)),
              DataCell(Text(book.availability)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        // TODO: Handle Edit action.
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // TODO: Handle Delete action.
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format current time and date using Intl.
    final String formattedTime = DateFormat('hh:mm a').format(_currentTime);
    final String formattedDate = DateFormat('MMM dd, yyyy').format(_currentTime);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: Use a Column layout if screen width is less than 800.
          if (constraints.maxWidth < 800) {
            return Column(
              children: [
                // Top bar for mobile view (combines logo and time/date).
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/logo_dark.png',
                        width: 80,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formattedTime,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Main content (stacked vertically)
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Book Management',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Handle Add Book action.
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Book'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 180,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search by ID or Name',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: buildBookDataTable(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          // Desktop / large screen layout: Sidebar + Main Content side by side.
          else {
            return Row(
              children: [
                // LEFT SIDEBAR
                Container(
                  width: 220,
                  color: const Color(0xFF594A47), // Dark brown background
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo area
                      Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/logo_dark.png', // Adjust asset path as needed
                          width: 90,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Navigation items
                      ListTile(
                        leading: const Icon(Icons.dashboard, color: Colors.white),
                        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.library_books, color: Colors.white),
                        title: const Text('Catalog', style: TextStyle(color: Colors.white)),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.book, color: Colors.white),
                        title: const Text('Books', style: TextStyle(color: Colors.white)),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.people, color: Colors.white),
                        title: const Text('Users', style: TextStyle(color: Colors.white)),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.store, color: Colors.white),
                        title: const Text('Branches', style: TextStyle(color: Colors.white)),
                        onTap: () {},
                      ),
                      const Spacer(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.white),
                        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          // TODO: Handle logout
                        },
                      ),
                    ],
                  ),
                ),
                // RIGHT MAIN CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TOP BAR
                      Container(
                        color: Colors.white,
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // User info (Name and Role)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Nisal Gunasekara', style: TextStyle(fontSize: 16)),
                                Text('Admin', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                            // Time and Date
                            Row(
                              children: [
                                Text(
                                  formattedTime,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  formattedDate,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Main content: Book Management interface
                      Expanded(
                        child: Container(
                          color: const Color(0xFFFFF3EB), // Light peach background
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Book Management',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Handle Add Book action
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Book'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown[700],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 220,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Search by ID or Name',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: buildBookDataTable(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
