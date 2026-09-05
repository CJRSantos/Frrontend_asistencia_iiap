import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/api_client.dart';
import '../widgets/leaf_logo.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  void _showServerConfigDialog() {
    final ctrl = TextEditingController(text: ApiConfig.baseUrl);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ConfiguraciÃ³n del Servidor Backend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'URL del servidor NestJS:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'http://localhost:3000/api o http://192.168.1.108:3000/api',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => ctrl.text = 'http://localhost:3000/api',
                    child: const Text('localhost (USB)', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => ctrl.text = ApiConfig.localWifiUrl,
                    child: const Text('Wi-Fi Local', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5E2A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ApiConfig.setCustomBaseUrl(ctrl.text);
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  SnackBar(content: Text('Servidor configurado en: ${ApiConfig.baseUrl}')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Â¡Bienvenido(a), ${user.fullName}!',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D5E2A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillQuickAdmin() {
    _emailController.text = 'jhon.martinez@iiap.gob.pe';
    _passwordController.text = '123456';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            LeafLogo(size: 26, color: isDark ? const Color(0xFF81C784) : const Color(0xFF2D5E2A)),
            const SizedBox(width: 10),
            Text(
              'IIAP Asistencia',
              style: TextStyle(
                color: isDark ? const Color(0xFF81C784) : const Color(0xFF1E4720),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.dns_outlined,
              color: isDark ? const Color(0xFF81C784) : const Color(0xFF1E4720),
            ),
            tooltip: 'Configurar Servidor',
            onPressed: _showServerConfigDialog,
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.themeModeNotifier,
            builder: (context, mode, _) {
              final activeDark = mode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  activeDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: activeDark ? const Color(0xFFFFB74D) : const Color(0xFF1E4720),
                ),
                tooltip: activeDark ? 'Modo Claro' : 'Modo Oscuro',
                onPressed: () => ThemeService.toggleDarkMode(!activeDark),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF14532D).withValues(alpha: 0.4)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.fingerprint_rounded,
                                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Iniciar SesiÃ³n',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Control de Asistencias IIAP',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Ingresa tus credenciales institucionales para acceder al registro de asistencias y escaneo de cÃ³digos QR.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Campos del Formulario
                    AppTextField(
                      controller: _emailController,
                      label: 'Correo ElectrÃ³nico',
                      hint: 'ejemplo@iiap.gob.pe',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu correo electrÃ³nico';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Ingresa un correo electrÃ³nico vÃ¡lido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _passwordController,
                      label: 'ContraseÃ±a',
                      hint: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu contraseÃ±a';
                        }
                        if (value.length < 6) {
                          return 'La contraseÃ±a debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // BotÃ³n de Inicio de SesiÃ³n
                    AppButton(
                      text: 'Entrar al Sistema',
                      icon: Icons.login_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: 16),

                    // BotÃ³n rÃ¡pido de prueba para Administrador
                    Center(
                      child: TextButton.icon(
                        onPressed: _fillQuickAdmin,
                        icon: const Icon(Icons.flash_on, size: 16, color: Color(0xFFD97706)),
                        label: const Text(
                          'Cargar cuenta Admin de prueba',
                          style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Enlace a Registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Â¿AÃºn no tienes cuenta? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            'RegÃ­strate aquÃ­',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                            ),
                          ),
                        ),
                      ],
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
}
