import 'package:geolocator/geolocator.dart';

class GpsLocation {
  const GpsLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class GpsHelper {
  GpsHelper._();

  /// Verifica permisos y obtiene la ubicación actual del dispositivo.
  static Future<GpsLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('El GPS está desactivado.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permiso de ubicación denegado permanentemente. Actívalo desde ajustes.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return GpsLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Retorna true si la aplicación tiene permiso para usar ubicación.
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Abre la configuración del dispositivo para activar permisos o GPS.
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}