import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("ENV LOAD ERROR: $e");
  }

  runApp(const RuralTourismApp());
}

class RuralTourismApp extends StatelessWidget {
  const RuralTourismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rural Tourism Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const DashboardScreen(),
    );
  }
}