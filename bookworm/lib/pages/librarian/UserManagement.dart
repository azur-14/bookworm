import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../model/User.dart';

/// Validate email with a regular expression.
bool isValidEmail(String email) {
  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

/// Validate phone: only digits and length between 9 and 12.
bool isValidPhone(String phone) {
  final RegExp phoneRegex = RegExp(r'^\d{9,12}$');
  return phoneRegex.hasMatch(phone);
}

/// Show a dialog with a validation error message.
Future<void> showValidationErrorDialog(BuildContext context, String message) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Error', style: TextStyle(color: Colors.red)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late DateTime _currentTime;
  Timer? _timer;

  // Sample user data (3 users).
  final List<User> _users = [
    User(
      id: '1',
      avatar: '',
      password: 'admin123',
      role: 'admin', // Will be hidden from the list.
      status: 'active',
      name: 'Admin One',
      email: 'admin@example.com',
      phone: '111222333',
      timeCreate: DateTime.parse("2021-01-01T10:00:00"),
    ),
    User(
      id: '2',
      avatar: '',
      password: 'lib456',
      role: 'customer',
      status: 'active',
      name: 'Librarian One',
      email: 'librarian@example.com',
      phone: '444555666',
      timeCreate: DateTime.parse("2021-02-02T11:00:00"),
    ),
    User(
      id: '3',
      avatar: '',
      password: 'cust789',
      role: 'customer',
      status: 'active',
      name: 'Customer One',
      email: 'customer@example.com',
      phone: '777888999',
      timeCreate: DateTime.now(),
    ),
  ];

  // Allow roles: only librarian and customer.
  final List<String> _roles = ['librarian', 'customer'];
  final List<String> _statuses = ['active', 'block'];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
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

  /// Generate a random password of given length.
  String generateRandomPassword(int length) {
    const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random rnd = Random();
    return List.generate(length, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Returns a TextField for normal data input.
  Widget _buildTextField(TextEditingController controller, String label,
      {bool numericOnly = false, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: numericOnly ? TextInputType.number : TextInputType.text,
    );
  }

  /// Returns a TextField for the password with toggle and random buttons.
  Widget _buildPasswordFieldWithToggle(TextEditingController controller,
      String label, bool passwordVisible, VoidCallback toggleVisibility) {
    return TextField(
      controller: controller,
      obscureText: !passwordVisible,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.brown[700]),
              onPressed: toggleVisibility,
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.brown[700]),
              onPressed: () {
                final newPass = generateRandomPassword(8);
                controller.text = newPass;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Read-only field style similar to BookManagement.
  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: AutoSizeText(
              '$label:',
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
          ),
          Expanded(
            child: AutoSizeText(
              value,
              maxLines: 1,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog to add a new user.
  Future<void> _showAddUserDialog() async {
    bool passwordVisible = false;
    final passwordCtl = TextEditingController();
    final nameCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    String selRole = _roles.first;
    String selStatus = "block"; // default insert status is block.
    String? base64Avatar;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.person_add, color: Colors.brown),
                const SizedBox(width: 8),
                AutoSizeText(
                  'Add User',
                  maxLines: 1,
                  style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameCtl, 'Name'),
                    const SizedBox(height: 12),
                    _buildTextField(emailCtl, 'Email'),
                    const SizedBox(height: 12),
                    _buildTextField(phoneCtl, 'Phone', numericOnly: true),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: _roles.map((role) => DropdownMenuItem(value: role, child: AutoSizeText(role, maxLines: 1))).toList(),
                      onChanged: (value) => setStateDialog(() => selRole = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses.map((status) => DropdownMenuItem(value: status, child: AutoSizeText(status, maxLines: 1))).toList(),
                      onChanged: (value) => setStateDialog(() => selStatus = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordFieldWithToggle(passwordCtl, 'Password', passwordVisible, () {
                      setStateDialog(() {
                        passwordVisible = !passwordVisible;
                      });
                    }),
                    const SizedBox(height: 12),
                    // Avatar picker row.
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              final base64String = base64Encode(bytes);
                              setStateDialog(() {
                                base64Avatar = base64String;
                              });
                            }
                          },
                          icon: const Icon(Icons.photo),
                          label: const Text('Choose Avatar'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown[700]),
                        ),
                        const SizedBox(width: 8),
                        if (base64Avatar != null)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: MemoryImage(base64Decode(base64Avatar!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const AutoSizeText('CANCEL', maxLines: 1),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (nameCtl.text.trim().isEmpty) {
                    await showValidationErrorDialog(context, "Name không được để trống.");
                    return;
                  }
                  if (!isValidEmail(emailCtl.text.trim())) {
                    await showValidationErrorDialog(context, "Email không đúng định dạng.");
                    return;
                  }
                  if (!isValidPhone(phoneCtl.text.trim())) {
                    await showValidationErrorDialog(context, "Số điện thoại không hợp lệ.");
                    return;
                  }
                  setState(() {
                    _users.add(User(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      password: passwordCtl.text,
                      name: nameCtl.text,
                      email: emailCtl.text,
                      phone: phoneCtl.text,
                      avatar: base64Avatar ?? '',
                      role: selRole,
                      status: selStatus,
                      timeCreate: DateTime.now(),
                    ));
                  });
                  Navigator.pop(ctx);
                },
                child: const AutoSizeText('ADD', maxLines: 1),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog to update an existing user.
  Future<void> _showUpdateUserDialog(User user) async {
    bool passwordVisible = false;
    final passwordCtl = TextEditingController(text: user.password);
    final nameCtl = TextEditingController(text: user.name);
    final emailCtl = TextEditingController(text: user.email);
    final phoneCtl = TextEditingController(text: user.phone);
    String? base64Avatar = user.avatar;
    String selRole = user.role;
    String selStatus = user.status;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.edit, color: Colors.brown),
                const SizedBox(width: 8),
                AutoSizeText('Update User', maxLines: 1, style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameCtl, 'Name'),
                  const SizedBox(height: 12),
                  _buildTextField(emailCtl, 'Email'),
                  const SizedBox(height: 12),
                  _buildTextField(phoneCtl, 'Phone', numericOnly: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: _roles.map((role) => DropdownMenuItem(value: role, child: AutoSizeText(role, maxLines: 1))).toList(),
                    onChanged: (value) => setStateDialog(() => selRole = value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.map((status) => DropdownMenuItem(value: status, child: AutoSizeText(status, maxLines: 1))).toList(),
                    onChanged: (value) => setStateDialog(() => selStatus = value!),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordFieldWithToggle(passwordCtl, 'Password', passwordVisible, () {
                    setStateDialog(() {
                      passwordVisible = !passwordVisible;
                    });
                  }),
                  const SizedBox(height: 12),
                  // Avatar selection row.
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            final base64String = base64Encode(bytes);
                            setStateDialog(() {
                              base64Avatar = base64String;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo),
                        label: const Text('Choose Avatar'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown[700]),
                      ),
                      const SizedBox(width: 8),
                      if (base64Avatar != null)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(base64Avatar!)),
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
                onPressed: () => Navigator.pop(ctx),
                child: const AutoSizeText('CANCEL', maxLines: 1),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (nameCtl.text.trim().isEmpty) {
                    await showValidationErrorDialog(context, "Name không được để trống.");
                    return;
                  }
                  if (!isValidEmail(emailCtl.text.trim())) {
                    await showValidationErrorDialog(context, "Email không đúng định dạng.");
                    return;
                  }
                  if (!isValidPhone(phoneCtl.text.trim())) {
                    await showValidationErrorDialog(context, "Số điện thoại không hợp lệ.");
                    return;
                  }
                  setState(() {
                    user.password = passwordCtl.text;
                    user.name = nameCtl.text;
                    user.email = emailCtl.text;
                    user.phone = phoneCtl.text;
                    user.avatar = base64Avatar ?? '';
                    user.role = selRole;
                    user.status = selStatus;
                  });
                  Navigator.pop(ctx);
                },
                child: const AutoSizeText('UPDATE', maxLines: 1),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog to view a user's details (read-only).
  Future<void> _showViewUserDialog(User user) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.visibility_outlined, color: Colors.brown),
            const SizedBox(width: 8),
            AutoSizeText('View User', maxLines: 1, style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReadOnlyField('ID', user.id),
              _buildReadOnlyField('Name', user.name),
              _buildReadOnlyField('Email', user.email),
              _buildReadOnlyField('Phone', user.phone),
              _buildReadOnlyField('Avatar', user.avatar.isNotEmpty ? 'Base64 String' : 'No Avatar'),
              _buildReadOnlyField('Role', user.role),
              _buildReadOnlyField('Status', user.status),
              _buildReadOnlyField('Created', DateFormat('MMM dd, yyyy').format(user.timeCreate)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const AutoSizeText('CLOSE', maxLines: 1),
          ),
        ],
      ),
    );
  }

  /// Dialog to confirm deletion of a user.
  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete "${user.email}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _users.remove(user);
              });
              Navigator.pop(ctx);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  /// Build a responsive table displaying the list of users.
  Widget _buildTable() {
    // Filter out admin users if needed.
    List<User> displayUsers = _users.where((user) => user.role != 'admin').toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: displayUsers.map((user) {
                return DataRow(
                  cells: [
                    DataCell(Text(user.id)),
                    DataCell(Text(user.name, overflow: TextOverflow.ellipsis)),
                    DataCell(Text(user.email)),
                    DataCell(Text(user.phone)),
                    DataCell(Text(user.role)),
                    DataCell(Text(user.status)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () => _showViewUserDialog(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.brown),
                            onPressed: () => _showUpdateUserDialog(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(user),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = DateFormat('hh:mm a').format(_currentTime);
    final String formattedDate = DateFormat('MMM dd, yyyy').format(_currentTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFFFF3EB),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AutoSizeText('User Management',
                    maxLines: 1,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.add),
                      label: const AutoSizeText('Add User', maxLines: 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[700],
                        foregroundColor: const Color(0xFFFFF3EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by Name or Email',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildTable(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [AutoSizeText('$formattedDate, $formattedTime', maxLines: 1)],
          ),
        ),
      ],
    );
  }
}

