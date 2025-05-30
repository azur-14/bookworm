import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/Book.dart';
import 'package:bookworm/model/Category.dart';
import 'package:bookworm/pages/customer/BookDetailPage.dart';

import '../../widgets/Customer/BookGallery.dart';
import '../../widgets/Customer/BookSortFilter.dart';

class BookShelfPage extends StatefulWidget {
  const BookShelfPage({Key? key}) : super(key: key);

  @override
  _BookShelfPageState createState() => _BookShelfPageState();
}

class _BookShelfPageState extends State<BookShelfPage> {
  // Controllers & Notifiers
  final TextEditingController _searchCtl = TextEditingController();
  final ValueNotifier<String> _filter = ValueNotifier('');
  final ValueNotifier<bool> _gridView = ValueNotifier(true);
  final ValueNotifier<String?> _selectedCategory = ValueNotifier(null);
  final ValueNotifier<String?> _selectedPublisher = ValueNotifier(null);
  final ValueNotifier<String> _sortOption = ValueNotifier('A-Z');
  final ValueNotifier<int> _combinedNotifier = ValueNotifier(0);

  // New filter notifiers
  final ValueNotifier<RangeValues> _yearRange = ValueNotifier(const RangeValues(0, 0));
  final ValueNotifier<RangeValues> _priceRange = ValueNotifier(const RangeValues(0, 0));
  final ValueNotifier<bool> _availableOnly = ValueNotifier(false);

  // Min/max for sliders
  late double _minYear;
  late double _maxYear;
  late double _minPrice;
  late double _maxPrice;

  // Data
  bool _isLoading = true;
  String? _error;
  final List<Book> _books = [];
  final List<Category> _categories = [];
  final List<String> _publishers = [];

  @override
  void initState() {
    super.initState();
    _searchCtl.addListener(() => _filter.value = _searchCtl.text.toLowerCase());
    _filter.addListener(() => _combinedNotifier.value++);
    _gridView.addListener(() => _combinedNotifier.value++);
    _selectedCategory.addListener(() => _combinedNotifier.value++);
    _selectedPublisher.addListener(() => _combinedNotifier.value++);
    _sortOption.addListener(() => _combinedNotifier.value++);
    // new listeners
    _yearRange.addListener(() => _combinedNotifier.value++);
    _priceRange.addListener(() => _combinedNotifier.value++);
    _availableOnly.addListener(() => _combinedNotifier.value++);

    _loadData();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _filter.dispose();
    _gridView.dispose();
    _selectedCategory.dispose();
    _selectedPublisher.dispose();
    _sortOption.dispose();
    _combinedNotifier.dispose();
    _yearRange.dispose();
    _priceRange.dispose();
    _availableOnly.dispose();
    super.dispose();
  }

  Future<List<Book>> fetchBooks() async {
    final response = await http.get(Uri.parse('http://localhost:3003/api/books'));
    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((j) => Book.fromJson(j)).toList();
    }
    throw Exception('Failed to load books: ${response.statusCode}');
  }

  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('http://localhost:3003/api/categories'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((j) => Category.fromJson(j)).toList();
    }
    throw Exception('Failed to load categories: ${response.statusCode}');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final books = await fetchBooks();
      final categories = await fetchCategories();
      final publishers = books.map((b) => b.publisher).toSet().toList()..sort();

      // compute min/max
      final years = books.map((b) => b.publishYear).toList();
      _minYear = years.reduce(min).toDouble();
      _maxYear = years.reduce(max).toDouble();
      final prices = books.map((b) => b.price).toList();
      _minPrice = prices.reduce(min);
      _maxPrice = prices.reduce(max);

      // initialize sliders
      _yearRange.value = RangeValues(_minYear, _maxYear);
      _priceRange.value = RangeValues(_minPrice, _maxPrice);

      setState(() {
        _books
          ..clear()
          ..addAll(books);
        _categories
          ..clear()
          ..addAll(categories);
        _publishers
          ..clear()
          ..addAll(publishers);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data. Please try again.';
      });
    }
  }

  List<Book> _sortBooks(List<Book> books) {
    switch (_sortOption.value) {
      case 'A-Z':           return books..sort((a,b) => a.title.compareTo(b.title));
      case 'Z-A':           return books..sort((a,b) => b.title.compareTo(a.title));
      case 'Newest':        return books..sort((a,b) => b.timeCreate.compareTo(a.timeCreate));
      case 'Oldest':        return books..sort((a,b) => a.timeCreate.compareTo(b.timeCreate));
      case 'Price Low-High':return books..sort((a,b) => a.price.compareTo(b.price));
      case 'Price High-Low':return books..sort((a,b) => b.price.compareTo(a.price));
      default:              return books..sort((a,b) => a.title.compareTo(b.title));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: _combinedNotifier,
                builder: (_, __, ___) {
                  final txt = _filter.value.toLowerCase();
                  final yr = _yearRange.value;
                  final pr = _priceRange.value;
                  final availOnly = _availableOnly.value;

                  final filtered = _books.where((b) {
                    final okText = b.title.toLowerCase().contains(txt) ||
                        b.author.toLowerCase().contains(txt);
                    final okCat = _selectedCategory.value == null ||
                        b.categoryId == _selectedCategory.value;
                    final okPub = _selectedPublisher.value == null ||
                        b.publisher == _selectedPublisher.value;
                    final okYear = b.publishYear >= yr.start.round() &&
                        b.publishYear <= yr.end.round();
                    final okPrice = b.price >= pr.start && b.price <= pr.end;
                    final okAvail = !availOnly || b.availableQuantity > 0;
                    return okText && okCat && okPub && okYear && okPrice && okAvail;
                  }).toList();

                  final sorted = _sortBooks(filtered);

                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (_error != null) {
                    return Center(
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadData,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 7,
                          child: BookGallery(
                            books: sorted,
                            categories: _categories,
                            gridView: _gridView.value,
                          ),
                        ),
                        FilterSortPanel(
                          searchController: _searchCtl,
                          selectedCategory: _selectedCategory,
                          selectedPublisher: _selectedPublisher,
                          yearRange: _yearRange,
                          priceRange: _priceRange,
                          availableOnly: _availableOnly,
                          sortOption: _sortOption,
                          minYear: _minYear,
                          maxYear: _maxYear,
                          minPrice: _minPrice,
                          maxPrice: _maxPrice,
                          categories: _categories,
                          publishers: _publishers,
                          reloadData: _loadData,
                          showCategoryPicker: _showCategoryPicker,
                          showPublisherPicker: _showPublisherPicker,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary,
      child: Row(
        children: [
          Text('Browse & Borrow',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: _gridView,
            builder: (_, grid, __) => IconButton(
              icon: Icon(grid ? Icons.list : Icons.grid_view, color: Colors.white),
              onPressed: () => _gridView.value = !grid,
              tooltip: grid ? 'Switch to List' : 'Switch to Grid',
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search categories',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('All Categories'),
                    selected: _selectedCategory.value == null,
                    onTap: () {
                      _selectedCategory.value = null;
                      Navigator.pop(context);
                    },
                    leading: const Icon(Icons.clear_all),
                  ),
                  ..._categories
                      .where((c) => c.name.toLowerCase().contains(controller.text.toLowerCase()))
                      .map((c) => ListTile(
                    title: Text(c.name),
                    selected: c.id == _selectedCategory.value,
                    onTap: () {
                      _selectedCategory.value = c.id;
                      Navigator.pop(context);
                    },
                    leading: const Icon(Icons.category),
                  ))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPublisherPicker(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search publishers',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('All Publishers'),
                    selected: _selectedPublisher.value == null,
                    onTap: () {
                      _selectedPublisher.value = null;
                      Navigator.pop(context);
                    },
                    leading: const Icon(Icons.clear_all),
                  ),
                  ..._publishers
                      .where((p) => p.toLowerCase().contains(controller.text.toLowerCase()))
                      .map((p) => ListTile(
                    title: Text(p),
                    selected: p == _selectedPublisher.value,
                    onTap: () {
                      _selectedPublisher.value = p;
                      Navigator.pop(context);
                    },
                    leading: const Icon(Icons.business),
                  ))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
