// lib/pages/admin/systemconfig.dart
import 'package:flutter/material.dart';
import 'package:bookworm/model/SystemConfig.dart';
import 'package:bookworm/theme/AppColor.dart';

class SystemConfigPage extends StatefulWidget {
  @override
  _SystemConfigPageState createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage> {
  final _formKey = GlobalKey<FormState>();

  List<SystemConfig> _configs = [
    SystemConfig(id: 1, configName: 'damage_fee_percent', configValue: '10'),
    // vẫn giữ key cũ, nhưng giá trị giờ thể hiện VNĐ/ngày
    SystemConfig(id: 2, configName: 'overdue_fee_per_day', configValue: '2000'),
    SystemConfig(id: 4, configName: 'max_advance_booking_days', configValue: '7'),
    SystemConfig(id: 5, configName: 'max_loan_days', configValue: '14'),
  ];

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var cfg in _configs)
        cfg.configName: TextEditingController(text: cfg.configValue),
    };
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      for (var cfg in _configs) {
        cfg.configValue = _controllers[cfg.configName]!.text.trim();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã lưu cấu hình (giả lập)'),
        backgroundColor: Colors.brown.shade700,
      ),
    );
  }

  Widget _buildField(String key, String label, String suffix) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          suffixText: suffix,
          labelStyle: TextStyle(color: Colors.brown.shade700, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.brown.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.brown.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Không thể để trống' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // trong build() của _SystemConfigPageState:

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cấu hình hệ thống',
          style: TextStyle(color: Colors.white),   // ← text trắng
        ),
        backgroundColor: Colors.brown.shade700,
        elevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        'Thiết lập chung',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildField('damage_fee_percent', 'Phí hư hỏng', '%'),
                      // **Chỉ khác ở dòng này:**
                      _buildField('overdue_fee_per_day', 'Phí trễ hạn', 'VNĐ/ngày'),
                      const SizedBox(height: 24),
                      Text(
                        'Giới hạn ngày',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildField('max_advance_booking_days', 'Đặt trước tối đa', 'ngày'),
                      _buildField('max_loan_days', 'Mượn tối đa', 'ngày'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'LƯU CẤU HÌNH',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

