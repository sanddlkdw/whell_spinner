import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WheelSpinnerApp());
}

class WheelSpinnerApp extends StatelessWidget {
  const WheelSpinnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '转盘工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
