import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Ubicación aproximada del usuario, cacheada en memoria durante toda la
/// sesión. Se pide una sola vez cuando alguien la observa; si el usuario
/// rechaza el permiso el provider devuelve null y todo lo dependiente
/// (ordenamiento por cercanía, distancia en la card) simplemente no aparece.
///
/// Precisión `high`: la posición se usa para centrar mapas, marcar dónde
/// está el trabajo del cliente y ordenar prestadores por cercanía — todos
/// casos donde "aproximado a nivel de barrio" no basta. El costo de batería
/// es puntual (una lectura por sesión, no streaming).
final userLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } on Exception {
      // El fix GPS de alta precisión puede tardar más que el timeout en
      // interiores; caer a la última posición conocida antes que a nada.
      return await Geolocator.getLastKnownPosition();
    }
  } catch (_) {
    return null;
  }
});
