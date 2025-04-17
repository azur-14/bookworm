import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Data model for the pie chart
class ChartData {
  final String label;
  final int value;
  final Color color;
  ChartData(this.label, this.value, this.color);
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  /// Converts ChartData -> PieChartSectionData for fl_chart
  List<PieChartSectionData> _buildPieChartSections(List<ChartData> data) {
    final int total = data.fold(0, (sum, item) => sum + item.value);
    return data.map((d) {
      final percent = (d.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        color: d.color,
        value: d.value.toDouble(),
        title: '${d.label}\n$percent%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Sample data
    final int totalUsers = 150;
    final int totalBooks = 500;
    final int totalRooms = 10;
    final int borrowedBooks = 120;
    final int availableBooks = totalBooks - borrowedBooks;

    final overdueBorrowers = [
      {'name': 'Samith Gunasekara', 'book': 'Book ID: 123'},
      {'name': 'Ramesh Fernando', 'book': 'Book ID: 456'},
      {'name': 'John Doe', 'book': 'Book ID: 789'},
    ];

    final admins = [
      {'name': 'Nisal Gunasekara', 'role': 'Admin ID: 01'},
      {'name': 'Roshan Silva', 'role': 'Admin ID: 02'},
    ];

    // Pie chart data
    final List<ChartData> chartData = [
      ChartData('Borrowed', borrowedBooks, const Color(0xFF7B4F3C)),
      ChartData('Available', availableBooks, const Color(0xFFB29A8F)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EB), // Cream background
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;

          if (width < 600) {
            // SMALL SCREEN: Single column
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pie chart block
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    child: _buildPieChartSection(chartData, borrowedBooks, borrowedBooks + availableBooks),
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildStatCard(iconData: Icons.person_outline, label: 'Total Users', value: totalUsers.toString().padLeft(4, '0'))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard(iconData: Icons.book_outlined, label: 'Total Books', value: totalBooks.toString().padLeft(4, '0'))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard(iconData: Icons.meeting_room_outlined, label: 'Total Rooms', value: totalRooms.toString().padLeft(4, '0'))),
                      ],
                    ),
                  ),
                  // Panels hidden on small
                ],
              ),
            );
          } else if (width < 900) {
            // MEDIUM SCREEN: Single column with Overdue Borrowers
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 350,
                    padding: const EdgeInsets.all(16),
                    child: _buildPieChartSection(chartData, borrowedBooks, borrowedBooks + availableBooks),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildStatCard(iconData: Icons.person_outline, label: 'Total Users', value: totalUsers.toString().padLeft(4, '0'))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard(iconData: Icons.book_outlined, label: 'Total Books', value: totalBooks.toString().padLeft(4, '0'))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard(iconData: Icons.meeting_room_outlined, label: 'Total Rooms', value: totalRooms.toString().padLeft(4, '0'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildPanel(
                      title: 'Overdue Borrowers',
                      items: overdueBorrowers,
                      panelColor: const Color(0xFFB29A8F),
                      height: 300,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // LARGE SCREEN
            // We'll do a row: the pie chart on left, the stats row & panels on the right
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Larger chart on the left
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildPieChartSection(chartData, borrowedBooks, borrowedBooks + availableBooks),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right side: a column containing the stats row on top, and two panels below
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        // Stats row
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(iconData: Icons.person_outline, label: 'Total Users', value: totalUsers.toString().padLeft(4, '0'))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard(iconData: Icons.book_outlined, label: 'Total Books', value: totalBooks.toString().padLeft(4, '0'))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard(iconData: Icons.meeting_room_outlined, label: 'Total Rooms', value: totalRooms.toString().padLeft(4, '0'))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Overdue Borrowers & BookWorm Admins side by side
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPanel(
                                  title: 'Overdue Borrowers',
                                  items: overdueBorrowers,
                                  panelColor: const Color(0xFFB29A8F),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildPanel(
                                  title: 'BookWorm Admins',
                                  items: admins,
                                  panelColor: const Color(0xFF7B4F3C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  /// Builds the pie chart section
  Widget _buildPieChartSection(List<ChartData> data, int borrowed, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _buildPieChartSections(data),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: AutoSizeText(
            'Borrowed: $borrowed, Available: ${total - borrowed}',
            maxLines: 1,
            maxFontSize: 18, // let it grow more
            minFontSize: 10,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
        ),
      ],
    );
  }

  /// Builds a stat card with auto sizing text
  Widget _buildStatCard({
    required IconData iconData,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 120), // ensure there's space
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF7B4F3C),
                borderRadius: BorderRadius.circular(8),
              ),
              width: 40,
              height: 40,
              child: Icon(iconData, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  value,
                  maxLines: 1,
                  maxFontSize: 24, // allow bigger text if space
                  minFontSize: 10,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                AutoSizeText(
                  label,
                  maxLines: 1,
                  maxFontSize: 18, // allow bigger label text
                  minFontSize: 8,
                  style: const TextStyle(color: Color(0xFF666666)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A reusable panel widget for Overdue Borrowers or BookWorm Admins
  Widget _buildPanel({
    required String title,
    required List<dynamic> items,
    required Color panelColor,
    double? height,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                title,
                maxLines: 1,
                maxFontSize: 18,
                minFontSize: 10,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: panelColor,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: AutoSizeText(item['name'] ?? '',
                          maxLines: 1, minFontSize: 8, maxFontSize: 16),
                      subtitle: AutoSizeText(
                        item.containsKey('book') ? item['book'] ?? '' : item['role'] ?? '',
                        maxLines: 1,
                        minFontSize: 8,
                        maxFontSize: 14,
                      ),
                      trailing: item.containsKey('book')
                          ? const Icon(Icons.arrow_forward_ios, size: 14)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
