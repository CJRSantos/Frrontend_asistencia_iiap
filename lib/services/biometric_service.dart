import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Comprueba si el hardware y el sistema soportan autenticación biométrica
  static Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  // Lista de tipos de biometría disponibles (fingerprint, face, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // Solicitar autenticación biométrica (Huella Dactilar o Face ID)
  static Future<bool> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
  }) async {
    final available = await isBiometricsAvailable();
    if (!available) {
      // Si el dispositivo no tiene hardware biométrico, no bloquear al usuario
      return true;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: false, // Permite PIN/patrón de respaldo si la huella falla
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'PasscodeNotSet') {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
