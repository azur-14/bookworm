// lib/pages/admin/systemconfig.dart
import 'package:flutter/material.dart';
import 'package:bookworm/model/SystemConfig.dart';
import 'package:bookworm/theme/AppColor.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SystemConfigPage extends StatefulWidget {
  @override
  _SystemConfigPageState createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage> {
  final _formKey = GlobalKey<FormState>();

  List<SystemConfig> _configs = [];

  Map<String, TextEditingController>? _controllers;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _controllers!.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      for (var cfg in _configs) {
        cfg.configValue = _controllers![cfg.configName]!.text.trim();
        await updateSystemConfig(cfg);  // Gửi API cập nhật
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã lưu cấu hình'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildField(String key, String label, String suffix) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: TextFormField(
        controller: _controllers![key],
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
    if (_controllers == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
                      // Đã bỏ _buildField('damage_fee_percent', 'Phí hư hỏng', '%'),
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

  Future<List<SystemConfig>> fetchSystemConfigs() async {
    final response = await http.get(Uri.parse('http://localhost:3004/api/systemConfig'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => SystemConfig.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load system configs: ${response.body}');
    }
  }

  Future<void> _loadRequests() async {
    try {
      final list = await fetchSystemConfigs();
      setState(() {
        _configs = list;
        _controllers = {
          for (var cfg in _configs)
            cfg.configName: TextEditingController(text: cfg.configValue),
        };
      });
    } catch (e) {
      debugPrint('Lỗi khi tải danh sách systemConfig: $e');
    }
  }

  Future<void> updateSystemConfig(SystemConfig config) async {
    final response = await http.put(
      Uri.parse('http://localhost:3004/api/systemConfig/${config.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'config_value': config.configValue}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update config ${config.configName}: ${response.body}');
    }
  }
}

