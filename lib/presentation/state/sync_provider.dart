import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  final _supabase = Supabase.instance.client;
  bool _isSyncing = false;

  // 1. Escuchar los cambios de red en tiempo real en tu iPhone
  void listenToConnectionChanges() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Si la lista no contiene 'none', significa que recuperamos conexión
      if (!results.contains(ConnectivityResult.none)) {
        print("🌐 ¡Conexión recuperada! Iniciando sincronización automática...");
        sincronizarRegistrosPendientes();
      }
    });
  }

  // 2. Proceso de subida masiva a Supabase
  Future<void> sincronizarRegistrosPendientes() async {
    // Evitar ejecuciones duplicadas simultáneas
    if (_isSyncing) return;
    _isSyncing = true;

    final box = Hive.box('vacunaciones_offline');
    if (box.isEmpty) {
      _isSyncing = false;
      return;
    }

    print("📦 Encontrados ${box.length} registros pendientes en Hive.");

    // Recorremos los registros locales uno por uno de forma inversa para poder borrarlos de forma segura
    for (int i = box.length - 1; i >= 0; i--) {
      final data = Map<String, dynamic>.from(box.getAt(i));
      
      try {
        String? remoteFotoUrl;

        // A. Subir la imagen guardada en la caché del iPhone al Storage de Supabase
        if (data['foto_path'] != null) {
          final file = File(data['foto_path']);
          if (await file.exists()) {
            final fileName = 'offline_${DateTime.now().millisecondsSinceEpoch}.jpg';
            
            // Sube el archivo al bucket 'mascotas' que creamos en Supabase
            await _supabase.storage.from('mascotas').upload(fileName, file);
            
            // Obtener la URL pública de la imagen
            remoteFotoUrl = _supabase.storage.from('mascotas').getPublicUrl(fileName);
          }
        }

        // B. Insertar el registro definitivo en la tabla relacional de PostgreSQL
        await _supabase.from('vacunaciones').insert({
          'propietario_nombre': data['propietario_nombre'],
          'nombre_mascota': data['nombre_mascota'],
          'latitud': data['latitud'],
          'longitud': data['longitud'],
          'foto_url': remoteFotoUrl, // Guardamos la URL de la nube, no la ruta local
          'fecha_hora': data['fecha_hora'],
          // 'vacunador_id': _supabase.auth.currentUser?.id, // Enlazar al ID del vacunador activo si aplica
        });

        // C. Si se guardó con éxito en la nube, lo borramos de la memoria local Hive
        await box.deleteAt(i);
        print("✅ Registro sincronizado y eliminado de la cola local.");

      } catch (e) {
        print("❌ Error al sincronizar el registro index $i: $e");
        // Si falla (ej. error de timeout), se mantiene en Hive para reintentarlo luego.
      }
    }

    _isSyncing = false;
  }
  
}