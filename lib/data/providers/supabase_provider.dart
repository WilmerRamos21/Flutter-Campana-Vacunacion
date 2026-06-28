import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider {
  // Instancia única de Supabase
  final _supabase = Supabase.instance.client;

  // 1. Insertar un registro de vacunación en la tabla
  Future<void> guardarRegistroNube(Map<String, dynamic> datos) async {
    await _supabase.from('vacunaciones').insert(datos);
  }

  // 2. Subir la foto de la mascota al Storage y devolver la URL pública
  Future<String> subirFoto(File imagen, String nombreArchivo) async {
    // Sube el archivo al bucket llamado 'mascotas'
    await _supabase.storage.from('mascotas').upload(nombreArchivo, imagen);
    
    // Genera y retorna el link público para guardarlo en la base de datos
    return _supabase.storage.from('mascotas').getPublicUrl(nombreArchivo);
  }

  // 3. Obtener el total de perros o gatos vacunados (Requerimiento del Dashboard)
  Future<int> contarMascotasPorTipo(String tipo) async {
    // Cuenta cuántos registros coinciden con 'perro' o 'gato'
    final response = await _supabase
        .from('vacunaciones')
        .select('id')
        .eq('tipo_mascota', tipo)
        .count(CountOption.exact);
        
    return response.count;
  }
}