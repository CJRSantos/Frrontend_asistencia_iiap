import '../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SettingsService {
  // GET /api/settings: Obtiene las preferencias del usuario.
  static Future<dynamic> getSettings() async {
    return await ApiService.get(ApiConfig.settings, requiresAuth: true);
  }

  // PATCH /api/settings/notifications: Alterna el estado de notificaciones {"enabled": bool}
  static Future<dynamic> toggleNotifications(bool enabled) async {
    return await ApiService.patch(
      ApiConfig.settingsNotifications,
      body: {'enabled': enabled},
      requiresAuth: true,
    );
  }

  // POST /api/settings/clear-cache: Limpia temporales y registra en historial
  static Future<Map<String, dynamic>> clearCache() async {
    final response = await ApiService.post(
      ApiConfig.settingsClearCache,
      requiresAuth: true,
    );
    return response is Map<String, dynamic>
        ? response
        : {'success': true, 'message': 'Caché de la aplicación y datos temporales eliminados correctamente.'};
  }

  // POST /api/settings/change-password: Actualiza contraseña validando la anterior con bcrypt
  static Future<dynamic> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await ApiService.post(
      ApiConfig.settingsChangePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
      requiresAuth: true,
    );
  }

  // POST /api/settings/verify-password: Verifica si la contraseña escrita es correcta
  static Future<dynamic> verifyPassword(String password) async {
    return await ApiService.post(
      ApiConfig.settingsVerifyPassword,
      body: {'password': password},
      requiresAuth: true,
    );
  }

  // DELETE /api/settings/account: Desactiva y realiza la baja de la cuenta del usuario autenticado
  static Future<dynamic> deleteAccount({
    String? password,
    String? reason,
  }) async {
    final body = <String, dynamic>{};
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;

    final response = await ApiService.delete(
      ApiConfig.settingsDeleteAccount,
      body: body.isNotEmpty ? body : null,
      requiresAuth: true,
    );
    await StorageService.clearSession();
    return response;
  }
}
