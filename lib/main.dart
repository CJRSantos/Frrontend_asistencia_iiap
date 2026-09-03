import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'IIAP Asistencia',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF2D5E2A),
            scaffoldBackgroundColor: const Color(0xFFF6F8F7),
            cardColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2D5E2A),
              primary: const Color(0xFF2D5E2A),
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1E4720),
              elevation: 0.5,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF4ADE80),
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900 Ultra Dark
            cardColor: const Color(0xFF1E293B), // Slate 800 Elevated Card
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E293B),
            ),
            dividerColor: const Color(0xFF334155),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4ADE80),
              secondary: Color(0xFF60A5FA),
              surface: Color(0xFF1E293B),
              onPrimary: Colors.black,
              onSurface: Colors.white,
              brightness: Brightness.dark,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              bodyMedium: TextStyle(color: Color(0xFFF8FAFC)),
              bodySmall: TextStyle(color: Color(0xFFCBD5E1)),
              titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              titleSmall: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
              labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Colors.white,
              elevation: 0.5,
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
