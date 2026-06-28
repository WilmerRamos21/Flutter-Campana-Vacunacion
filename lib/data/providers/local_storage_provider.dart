import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageProvider {
  // El mismo nombre de la caja que abriste en el main.dart
  static const String _boxName = 'vacunaciones_offline';

  // 1. Guardar un registro localmente
  Future<void> guardarRegistroLocal(Map<String, dynamic> datos) async {
    final box = Hive.box(_boxName);
    await box.add(datos);
  }

  // 2. Leer todos los registros pendientes (útil para la sincronización)
  List<Map<String, dynamic>> obtenerRegistrosPendientes() {
    final box = Hive.box(_boxName);
    // Convertimos los datos guardados de vuelta a un Mapa estándar de Dart
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // 3. Eliminar un registro específico (después de que se subió a Supabase con éxito)
  Future<void> eliminarRegistroLocal(int index) async {
    final box = Hive.box(_boxName);
    await box.deleteAt(index);
  }

  // 4. Contar cuántos registros pendientes hay (Requerimiento del Dashboard)
  int contarPendientes() {
    final box = Hive.box(_boxName);
    return box.length;
  }
}