import 'package:flutter/material.dart';
import 'Login.dart';
import 'AdminHome.dart';
import 'BookManagement.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: BookManagementPage(),// Đặt WelcomeScreen làm trang chính
    );
  }
}
