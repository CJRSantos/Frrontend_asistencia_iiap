import 'package:geolocator/geolocator.dart';

class LocationResult {
  final bool success;
  final Position? position;
  final String? errorMessage;

  LocationResult({required this.success, this.position, this.errorMessage});
}

class LocationService {
  // Sede Central IIAP Iquitos
  static const double sedeCentralLatitude = -3.7719;
  static const double sedeCentralLongitude = -73.2690;
  static const int sedeCentralRadiusMeters = 1000;

  // Obtener posición GPS actual del teléfono con verificación de permisos
  static Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el GPS está encendido en el teléfono
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(
        success: false,
        errorMessage: 'El GPS está desactivado en tu dispositivo. Por favor actívalo para verificar tu ubicación.',
      );
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(
          success: false,
          errorMessage: 'Permiso de ubicación denegado. Se requiere acceso al GPS para marcar asistencia.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(
        success: false,
        errorMessage: 'Los permisos de ubicación están permanentemente denegados. Habilítalos desde los ajustes de la app.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(success: true, position: position);
    } catch (e) {
      // Si la llamada con alta precisión demora, intentar con última posición conocida
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          return LocationResult(success: true, position: lastPosition);
        }
      } catch (_) {}

      return LocationResult(
        success: false,
        errorMessage: 'No se pudo obtener la señal GPS precisa: ${e.toString()}',
      );
    }
  }

  // Calcular distancia en metros a la Sede Central del IIAP
  static double getDistanceToSedeCentral(double latitude, double longitude) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      sedeCentralLatitude,
      sedeCentralLongitude,
    );
  }

  // Comprobar si está dentro del radio permitido de la Sede Central
  static bool isInsideSedeCentral(double latitude, double longitude, {int allowedRadius = sedeCentralRadiusMeters}) {
    final distance = getDistanceToSedeCentral(latitude, longitude);
    return distance <= allowedRadius;
  }
}
