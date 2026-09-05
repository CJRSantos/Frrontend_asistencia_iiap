import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/leaf_logo.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashGateScreen extends StatefulWidget {
  const SplashGateScreen({super.key});

  @override
  State<SplashGateScreen> createState() => _SplashGateScreenState();
}

class _SplashGateScreenState extends State<SplashGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Breve pausa para presentación visual fluida
    await Future.delayed(const Duration(milliseconds: 600));

    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await AuthService.getProfile();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          return;
        }
      } catch (_) {
        // Si el token falló, StorageService ya lo limpió en ApiClient
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LeafLogo(
              size: 72,
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
            ),
            const SizedBox(height: 20),
            Text(
              'IIAP Asistencia',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF81C784) : const Color(0xFF1E4720),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sistema de Control de Asistencia y QR',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
