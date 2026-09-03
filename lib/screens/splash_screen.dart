import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../widgets/leaf_logo.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _displayedText = 'I';
  final List<String> _steps = ['I', 'II', 'IIA', 'IIAP'];
  int _stepIndex = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _startAnimationSequence() {
    // Fast letter transition timer: 90ms per step
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (_stepIndex < _steps.length) {
        setState(() {
          _displayedText = _steps[_stepIndex];
        });
        _stepIndex++;
      } else {
        _timer?.cancel();
        // Pause before smooth transition to Login/Home screen
        Future.delayed(const Duration(milliseconds: 260), () async {
          if (!mounted) return;
          
          Widget destination = const LoginScreen();
          final token = await StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            // Autenticación biométrica opcional al abrir la app si está configurada
            final canBio = await BiometricService.isBiometricsAvailable();
            bool bioOk = true;
            if (canBio) {
              bioOk = await BiometricService.authenticate(
                localizedReason: 'Ingresa a Control Asistencia IIAP con tu huella dactilar',
              );
            }

            if (bioOk) {
              destination = const HomeScreen();
              try {
                await AuthService.getProfile();
              } catch (e) {
                if (e is ApiException && e.statusCode == 401) {
                  await StorageService.clearSession();
                  destination = const LoginScreen();
                }
              }
            } else {
              destination = const LoginScreen();
            }
          }

          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => destination,
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF527749),
              Color(0xFF3B6237),
              Color(0xFF254522),
              Color(0xFF152B14),
            ],
            stops: [0.0, 0.42, 0.78, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Center Logo & Animated Text
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const LeafLogo(
                      size: 54,
                      color: Color(0xFFA2E082),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 50),
                      child: Text(
                        _displayedText,
                        key: ValueKey<String>(_displayedText),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Footer Info
              Positioned(
                bottom: 34,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'CONTROL DE ASISTENCIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 1.2,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Instituto de Investigaciones de la',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Amazonía Peruana',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
