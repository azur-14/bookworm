import 'package:flutter/material.dart';
import 'package:bookworm/theme/AppColor.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  const SearchField({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Tìm user hoặc sách...',
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
