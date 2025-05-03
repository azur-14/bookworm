// lib/pages/PaymentScreen.dart
import 'package:flutter/material.dart';
import '../../theme/AppColor.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;
  final VoidCallback onSuccess;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isPaying = false;
  String? _selectedMethod;

  Widget _buildMethodCard(String label, IconData icon, String value) {
    final selected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
          selected ? AppColors.primary.withOpacity(0.15) : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: selected ? AppColors.primary : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalK = (widget.amount / 1000).toStringAsFixed(0);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Thanh toán online',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Chọn phương thức thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMethodCard('Ví Momo', Icons.account_balance_wallet, 'momo'),
                _buildMethodCard('Ngân hàng', Icons.account_balance, 'bank'),
                _buildMethodCard('Visa/Master', Icons.credit_card, 'visa'),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '$totalK K VNĐ',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _isPaying
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _selectedMethod == null
                  ? null
                  : () async {
                setState(() => _isPaying = true);
                await Future.delayed(const Duration(seconds: 2));
                setState(() => _isPaying = false);
                widget.onSuccess();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thanh toán thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text('Thanh toán ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
