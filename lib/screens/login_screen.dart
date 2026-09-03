import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/leaf_logo.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final status = await StorageService.getRememberMeStatus();
    if (status) {
      final email = await StorageService.getRememberedEmail();
      if (email != null && email.isNotEmpty && mounted) {
        setState(() {
          _rememberMe = true;
          _emailController.text = email;
        });
      }
    }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await AuthService.loginStep2(email, password);
      await StorageService.saveRememberMe(_rememberMe, email);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String message = e is ApiException ? e.message : 'Error al iniciar sesión: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
        }
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? token = auth.idToken ?? auth.accessToken;

      if (token != null && token.isNotEmpty) {
        await AuthService.googleLogin(token);
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
          _navigateToHome();
        }
      } else {
        await AuthService.googleLogin(account.email);
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
          _navigateToHome();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });

        if (e.toString().contains('MissingPluginException')) {
          _showMissingPluginDialog();
        } else if (e.toString().contains('sign_in_failed') || e.toString().contains('10')) {
          _showGoogleFallbackDialog();
        } else {
          String message = e is ApiException
              ? e.message
              : 'No se pudo autenticar con Google: ${e.toString().replaceAll("Exception: ", "")}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF374151),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _showMissingPluginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Reinicio Requerido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Se agregaron librerías nativas de Google a Flutter. Para que el celular reconozca el plugin nativo de Google:\n\n'
          '1. Detén el comando actual ("flutter run").\n'
          '2. Vuelve a ejecutar "flutter run" en la consola para recompilar el código nativo de Android.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF374151)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5E2A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showGoogleFallbackDialog() {
    final googleEmailCtrl = TextEditingController(
      text: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : '',
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              _buildGoogleIcon(),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Acceso con Cuenta Google',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa la dirección de tu cuenta Google para verificar el acceso instantáneo a la plataforma:',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: googleEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'ejemplo@gmail.com o correo institucional',
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4285F4), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final email = googleEmailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un correo de Google válido.')),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        await AuthService.googleLogin(email);
                        if (mounted) {
                          Navigator.of(ctx).pop();
                          _navigateToHome();
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          String msg = e is ApiException ? e.message : 'Error al autenticar: $e';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Continuar con Google', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F2F1);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E4720);
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF556B58);
    final inputTextColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF8E9A90);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Circle Leaf Icon Header
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF15803D) : const Color(0xFF2D5E2A),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: LeafLogo(
                            size: 34,
                            color: Color(0xFF9FE080),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title & Subtitle
                    Text(
                      'IIAP Asistencia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Plataforma de Control e Investigación',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Correo Institucional Input with Inline Warning
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: inputTextColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Correo institucional',
                        hintStyle: TextStyle(color: hintTextColor, fontSize: 15),
                        prefixIcon: Icon(Icons.email_outlined, color: hintTextColor, size: 20),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu correo institucional';
                        }
                        if (!value.contains('@')) {
                          return 'Ingresa un correo institucional válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contraseña Input with Inline Warning
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: inputTextColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        hintStyle: TextStyle(color: hintTextColor, fontSize: 15),
                        prefixIcon: Icon(Icons.lock_outline, color: hintTextColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: hintTextColor,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Remember Me & Forgot Password Row
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 10,
                      children: [
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                                      checkColor: isDark ? Colors.black : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: BorderSide(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF7A8A7D), width: 1.5),
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recordarme',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : const Color(0xFF405043),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(
                                    initialEmail: _emailController.text.trim(),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Login Button (Navigates to Home)
                    ElevatedButton(
                      onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF255323),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF255323).withValues(alpha: 0.6),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Separador O CONTINUAR CON
                    Row(
                      children: [
                        Expanded(child: Divider(color: borderColor, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'O CONTINUAR CON',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: borderColor, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Botón Continuar con Google
                    OutlinedButton(
                      onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        foregroundColor: isDark ? Colors.white : const Color(0xFF374151),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isGoogleLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF4285F4),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleIcon(),
                                const SizedBox(width: 12),
                                Text(
                                  'Continuar con Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF374151),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          splashColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              'Registrarme como nuevo investigador',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double cx = width / 2;
    final double cy = height / 2;
    final double radius = width / 2;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Red
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: radius), -0.7, 1.8, false)
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: radius), 1.1, 1.2, false)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: radius), 2.3, 1.5, false)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: radius), 3.8, 1.8, false)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Inner Cutout
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), radius * 0.58, paint);

    // Center Bar
    paint.color = const Color(0xFF4285F4);
    final Rect rect = Rect.fromLTWH(cx - radius * 0.1, cy - radius * 0.2, radius * 1.05, radius * 0.4);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
