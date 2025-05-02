import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bookworm/model/User.dart';
import 'UserTextField.dart';
import 'UserPasswordField.dart';
import 'package:bookworm/theme/AppColor.dart'; // 👈 Thêm dòng này

class UserAddUpdateDialog extends StatefulWidget {
  final User? user; // null -> Add, not null -> Update
  final void Function(User user) onSubmit;

  const UserAddUpdateDialog({
    Key? key,
    this.user,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<UserAddUpdateDialog> createState() => _UserAddUpdateDialogState();
}

class _UserAddUpdateDialogState extends State<UserAddUpdateDialog> {
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _passwordVisible = false;
  String _selRole = 'librarian';
  String _selStatus = 'block';
  String? _base64Avatar;
  final List<String> _roles = ['librarian', 'customer'];
  final List<String> _statuses = ['active', 'block'];

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameCtl.text = widget.user!.name;
      _emailCtl.text = widget.user!.email;
      _phoneCtl.text = widget.user!.phone;
      _passwordCtl.text = widget.user!.password;
      _selRole = widget.user!.role;
      _selStatus = widget.user!.status;
      _base64Avatar = widget.user!.avatar;
    }
  }

  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    final RegExp phoneRegex = RegExp(r'^\d{9,12}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Avatar = base64Encode(bytes);
      });
    }
  }

  void _submit() {
    if (_nameCtl.text.trim().isEmpty) {
      _showError("Name không được để trống.");
      return;
    }
    if (!isValidEmail(_emailCtl.text.trim())) {
      _showError("Email không đúng định dạng.");
      return;
    }
    if (!isValidPhone(_phoneCtl.text.trim())) {
      _showError("Số điện thoại không hợp lệ.");
      return;
    }

    final user = User(
      id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtl.text.trim(),
      email: _emailCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      password: _passwordCtl.text,
      avatar: _base64Avatar ?? '',
      role: _selRole,
      status: _selStatus,
      timeCreate: widget.user?.timeCreate ?? DateTime.now(),
    );

    widget.onSubmit(user);
    Navigator.pop(context);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)), // optional: define AppColors.error
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.user != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.person_add, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            isUpdate ? 'Update User' : 'Add User',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserTextField(controller: _nameCtl, label: 'Name'),
            const SizedBox(height: 12),
            UserTextField(controller: _emailCtl, label: 'Email'),
            const SizedBox(height: 12),
            UserTextField(controller: _phoneCtl, label: 'Phone', numericOnly: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selRole,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
              onChanged: (value) => setState(() => _selRole = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selStatus,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: _statuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
              onChanged: (value) => setState(() => _selStatus = value!),
            ),
            const SizedBox(height: 12),
            UserPasswordField(
              controller: _passwordCtl,
              label: 'Password',
              passwordVisible: _passwordVisible,
              toggleVisibility: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.photo),
                  label: const Text('Choose Avatar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                if (_base64Avatar != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(_base64Avatar!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'CANCEL',
            style: TextStyle(color: AppColors.primary),
          ),

        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          onPressed: _submit,
          child: Text(isUpdate ? 'UPDATE' : 'ADD'),
        ),
      ],
    );
  }
}
