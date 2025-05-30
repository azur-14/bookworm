import 'package:flutter/material.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'package:bookworm/model/Category.dart';

class FilterSortPanel extends StatelessWidget {
  final TextEditingController searchController;
  final ValueNotifier<String?> selectedCategory;
  final ValueNotifier<String?> selectedPublisher;
  final ValueNotifier<RangeValues> yearRange;
  final ValueNotifier<RangeValues> priceRange;
  final ValueNotifier<bool> availableOnly;
  final ValueNotifier<String> sortOption;
  final List<Category> categories;
  final List<String> publishers;
  final double minYear;
  final double maxYear;
  final double minPrice;
  final double maxPrice;
  final Future<void> Function() reloadData;
  final void Function(BuildContext) showCategoryPicker;
  final void Function(BuildContext) showPublisherPicker;

  const FilterSortPanel({
    Key? key,
    required this.searchController,
    required this.selectedCategory,
    required this.selectedPublisher,
    required this.yearRange,
    required this.priceRange,
    required this.availableOnly,
    required this.sortOption,
    required this.minYear,
    required this.maxYear,
    required this.minPrice,
    required this.maxPrice,
    required this.categories,
    required this.publishers,
    required this.reloadData,
    required this.showCategoryPicker,
    required this.showPublisherPicker,
  }) : super(key: key);

  String _catName(String? id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'All')).name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            // Search Field
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Search title or author',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            // Category Filter
            ValueListenableBuilder<String?>(
              valueListenable: selectedCategory,
              builder: (_, cat, __) => FilterChip(
                label: Text(
                  cat == null ? 'All Categories' : _catName(cat),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                selected: cat != null,
                onSelected: (_) => showCategoryPicker(context),
                avatar: const Icon(Icons.category, size: 18, color: AppColors.primary),
                selectedColor: AppColors.primary.withOpacity(0.1),
                checkmarkColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Publisher Filter
            ValueListenableBuilder<String?>(
              valueListenable: selectedPublisher,
              builder: (_, pub, __) => FilterChip(
                label: Text(
                  pub ?? 'All Publishers',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                selected: pub != null,
                onSelected: (_) => showPublisherPicker(context),
                avatar: const Icon(Icons.business, size: 18, color: AppColors.primary),
                selectedColor: AppColors.primary.withOpacity(0.1),
                checkmarkColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Year Range Filter
            ValueListenableBuilder<RangeValues>(
              valueListenable: yearRange,
              builder: (_, range, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publish Year: ${range.start.round()} - ${range.end.round()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  RangeSlider(
                    values: range,
                    min: minYear,
                    max: maxYear,
                    divisions: (maxYear - minYear).toInt(),
                    labels: RangeLabels(
                      range.start.round().toString(),
                      range.end.round().toString(),
                    ),
                    onChanged: (newRange) => yearRange.value = newRange,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Price Range Filter
            ValueListenableBuilder<RangeValues>(
              valueListenable: priceRange,
              builder: (_, range, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price: ${range.start.round()} - ${range.end.round()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  RangeSlider(
                    values: range,
                    min: minPrice,
                    max: maxPrice,
                    labels: RangeLabels(
                      range.start.round().toString(),
                      range.end.round().toString(),
                    ),
                    onChanged: (newRange) => priceRange.value = newRange,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Availability Filter
            ValueListenableBuilder<bool>(
              valueListenable: availableOnly,
              builder: (_, avail, __) => SwitchListTile(
                title: const Text('Available Only'),
                value: avail,
                onChanged: (newVal) => availableOnly.value = newVal,
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Sort Options
            ValueListenableBuilder<String>(
              valueListenable: sortOption,
              builder: (_, sort, __) => DropdownButton<String>(
                value: sortOption.value,
                items: const [
                  'A-Z',
                  'Z-A',
                  'Newest',
                  'Oldest',
                  'Price Low-High',
                  'Price High-Low',
                ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) {
                  if (v != null) sortOption.value = v;
                },
                isExpanded: true,
                underline: const SizedBox(),
                style: Theme.of(context).textTheme.bodyMedium,
                dropdownColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Reload Button
            ElevatedButton.icon(
              onPressed: reloadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
