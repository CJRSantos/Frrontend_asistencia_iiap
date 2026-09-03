import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _isTogglingNotifications = false;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await SettingsService.getSettings();
      if (res is Map<String, dynamic>) {
        if (res.containsKey('notifications_enabled')) {
          _notificationsEnabled = res['notifications_enabled'] == true;
        } else if (res.containsKey('enabled')) {
          _notificationsEnabled = res['enabled'] == true;
        }
      }
    } catch (_) {
      // Default to true
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleToggleNotifications(bool val) async {
    setState(() {
      _isTogglingNotifications = true;
      _notificationsEnabled = val;
    });

    try {
      await SettingsService.toggleNotifications(val);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(val ? 'Notificaciones activadas' : 'Notificaciones silenciadas'),
            backgroundColor: const Color(0xFF2D5E2A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _notificationsEnabled = !val);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar notificaciones: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingNotifications = false);
    }
  }

  Future<void> _handleClearCache() async {
    setState(() => _isClearingCache = true);
    try {
      final res = await SettingsService.clearCache();
      if (mounted) {
        final msg = res['message'] ?? 'Caché y datos temporales eliminados correctamente.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cleaning_services, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(msg)),
              ],
            ),
            backgroundColor: const Color(0xFF2D5E2A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al limpiar caché: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFF2D5E2A)),
              SizedBox(width: 8),
              Expanded(child: Text('Cambiar Contraseña')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa tu contraseña actual y define tu nueva clave de acceso.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPassCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Contraseña Actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_clock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5E2A),
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final curr = currentPassCtrl.text.trim();
                      final neu = newPassCtrl.text.trim();
                      final conf = confirmPassCtrl.text.trim();
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);

                      if (curr.isEmpty || neu.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Por favor completa todos los campos'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      if (neu != conf) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Las nuevas contraseñas no coinciden'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        await SettingsService.changePassword(currentPassword: curr, newPassword: neu);
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('¡Contraseña actualizada exitosamente!'),
                            backgroundColor: Color(0xFF2D5E2A),
                          ),
                        );
                      } on ApiException catch (e) {
                        setDialogState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyPasswordDialog() {
    final passCtrl = TextEditingController();
    bool isVerifying = false;
    String? verifyResult;
    bool obscureVerify = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF2D5E2A)),
              SizedBox(width: 8),
              Expanded(child: Text('Verificar Contraseña')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Valida si tu contraseña actual coincide con la registrada en la base de datos.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: obscureVerify,
                decoration: InputDecoration(
                  labelText: 'Ingresa tu contraseña',
                  prefixIcon: const Icon(Icons.password),
                  suffixIcon: IconButton(
                    icon: Icon(obscureVerify ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setDialogState(() => obscureVerify = !obscureVerify),
                  ),
                ),
              ),
              if (verifyResult != null) ...[
                const SizedBox(height: 12),
                Text(
                  verifyResult!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: verifyResult!.contains('correcta') ? const Color(0xFF2D5E2A) : Colors.red,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5E2A),
                foregroundColor: Colors.white,
              ),
              onPressed: isVerifying
                  ? null
                  : () async {
                      if (passCtrl.text.isEmpty) return;
                      setDialogState(() => isVerifying = true);
                      try {
                        final res = await SettingsService.verifyPassword(passCtrl.text);
                        final valid = res is Map ? (res['valid'] == true || res['success'] == true) : true;
                        setDialogState(() {
                          isVerifying = false;
                          verifyResult = valid ? '✓ Contraseña correcta y válida' : '✗ Contraseña incorrecta';
                        });
                      } catch (e) {
                        setDialogState(() {
                          isVerifying = false;
                          verifyResult = '✗ Contraseña incorrecta';
                        });
                      }
                    },
              child: isVerifying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verificar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool obscureDelete = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text('Eliminar / Desactivar Cuenta')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Esta acción desactivará tu cuenta en el sistema de asistencia del IIAP.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passCtrl,
                  obscureText: obscureDelete,
                  decoration: InputDecoration(
                    labelText: 'Contraseña para Confirmar',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureDelete ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setDialogState(() => obscureDelete = !obscureDelete),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo (Opcional)',
                  prefixIcon: Icon(Icons.comment),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SettingsService.deleteAccount(
                  password: passCtrl.text.trim(),
                  reason: reasonCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al dar de baja la cuenta: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Eliminar Mi Cuenta'),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1E4720);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3);
    final subtitleColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Ajustes y Configuración'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // SECCIÓN APARIENCIA Y TEMA
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeService.themeModeNotifier,
                  builder: (context, currentMode, _) {
                    final activeDark = currentMode == ThemeMode.dark;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apariencia y Tema',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sectionTitleColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          color: cardBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: cardBorderColor),
                          ),
                          child: SwitchListTile(
                            activeTrackColor: const Color(0xFF4ADE80),
                            title: Text('Modo Oscuro (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold, color: activeDark ? Colors.white : Colors.black)),
                            subtitle: Text(
                              activeDark ? 'Interfaz oscura activa para baja iluminación' : 'Interfaz clara estándar activa',
                              style: TextStyle(fontSize: 12.5, color: subtitleColor),
                            ),
                            value: activeDark,
                            onChanged: (val) {
                              ThemeService.toggleDarkMode(val);
                            },
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: activeDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                activeDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                color: activeDark ? const Color(0xFFFFB74D) : const Color(0xFF2D5E2A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                // SECCIÓN NOTIFICACIONES
                Text(
                  'Notificaciones y Alertas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sectionTitleColor),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: cardBorderColor),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                    title: Text('Notificaciones de Asistencia', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    subtitle: Text(
                      _notificationsEnabled
                          ? 'Recibir alertas de marcaciones y recordatorios'
                          : 'Notificaciones silenciadas',
                      style: TextStyle(fontSize: 12.5, color: subtitleColor),
                    ),
                    value: _notificationsEnabled,
                    onChanged: _isTogglingNotifications ? null : _handleToggleNotifications,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.notifications_active, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SECCIÓN SEGURIDAD
                Text(
                  'Seguridad de la Cuenta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sectionTitleColor),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: cardBorderColor),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF78350F) : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.lock_reset, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                        ),
                        title: Text('Cambiar Contraseña', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        subtitle: Text('Actualiza tu clave de acceso con validación segura', style: TextStyle(fontSize: 12.5, color: subtitleColor)),
                        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white70 : Colors.grey),
                        onTap: _showChangePasswordDialog,
                      ),
                      Divider(height: 1, color: cardBorderColor),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.password, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1976D2)),
                        ),
                        title: Text('Verificar Contraseña Actual', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        subtitle: Text('Comprueba si tu contraseña coincide en el servidor', style: TextStyle(fontSize: 12.5, color: subtitleColor)),
                        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white70 : Colors.grey),
                        onTap: _showVerifyPasswordDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECCIÓN ALMACENAMIENTO Y CACHÉ
                Text(
                  'Almacenamiento y Rendimiento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sectionTitleColor),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: cardBorderColor),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF581C87) : const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cleaning_services_rounded, color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE)),
                    ),
                    title: Text('Borrar Caché y Temporales', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    subtitle: Text('Libera espacio y limpia datos en caché del servidor', style: TextStyle(fontSize: 12.5, color: subtitleColor)),
                    trailing: _isClearingCache
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.chevron_right, color: isDark ? Colors.white70 : Colors.grey),
                    onTap: _isClearingCache ? null : _handleClearCache,
                  ),
                ),
                const SizedBox(height: 24),

                // SECCIÓN CUENTA Y DESACTIVACIÓN
                const Text(
                  'Zona de la Cuenta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.red.shade400),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF7F1D1D) : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.delete_forever, color: isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700),
                    ),
                    title: Text('Eliminar / Desactivar Cuenta', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700)),
                    subtitle: Text('Dar de baja definitiva a tu cuenta de colaborador', style: TextStyle(fontSize: 12.5, color: subtitleColor)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: _showDeleteAccountDialog,
                  ),
                ),
              ],
            ),
    );
  }
}
