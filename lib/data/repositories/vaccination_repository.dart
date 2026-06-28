import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vaccination_model.dart';

class VaccinationRepository {
  VaccinationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _tableName = 'vacunaciones';
  static const String _idColumn = 'id';
  static const String _sectorIdColumn = 'sector_id';
  static const String _vaccinatorIdColumn = 'vacunador_id';

  /// Obtiene todas las vacunaciones registradas.
  Future<List<VaccinationModel>> getVaccinations() async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .order('fecha_hora', ascending: false);

      return data.map<VaccinationModel>((item) {
        return VaccinationModel.fromJson(item);
      }).toList();
    } catch (error) {
      throw Exception('Error al obtener las vacunaciones: $error');
    }
  }

  /// Obtiene las vacunaciones filtradas por sector.
  Future<List<VaccinationModel>> getVaccinationsBySector(int sectorId) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq(_sectorIdColumn, sectorId)
          .order('fecha_hora', ascending: false);

      return data.map<VaccinationModel>((item) {
        return VaccinationModel.fromJson(item);
      }).toList();
    } catch (error) {
      throw Exception('Error al obtener vacunaciones por sector: $error');
    }
  }

  /// Obtiene las vacunaciones registradas por un vacunador.
  Future<List<VaccinationModel>> getVaccinationsByVaccinator(
    String userId,
  ) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq(_vaccinatorIdColumn, userId)
          .order('fecha_hora', ascending: false);

      return data.map<VaccinationModel>((item) {
        return VaccinationModel.fromJson(item);
      }).toList();
    } catch (error) {
      throw Exception('Error al obtener vacunaciones por vacunador: $error');
    }
  }

  /// Obtiene una vacunación por su ID.
  ///
  /// Retorna null si no existe ningún registro con ese ID.
  Future<VaccinationModel?> getVaccinationById(String id) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq(_idColumn, id)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return VaccinationModel.fromJson(data);
    } catch (error) {
      throw Exception('Error al obtener la vacunación: $error');
    }
  }

  /// Crea una nueva vacunación.
  Future<void> createVaccination(VaccinationModel vaccination) async {
    try {
      await _client.from(_tableName).insert(vaccination.toJson());
    } catch (error) {
      throw Exception('Error al crear la vacunación: $error');
    }
  }

  /// Actualiza una vacunación existente.
  Future<void> updateVaccination(VaccinationModel vaccination) async {
    try {
      if (vaccination.id == null || vaccination.id!.isEmpty) {
        throw Exception('El ID de la vacunación es requerido para actualizar.');
      }

      await _client
          .from(_tableName)
          .update(vaccination.toUpdateJson())
          .eq(_idColumn, vaccination.id!);
    } catch (error) {
      throw Exception('Error al actualizar la vacunación: $error');
    }
  }

  /// Elimina una vacunación por su ID.
  Future<void> deleteVaccination(String id) async {
    try {
      await _client.from(_tableName).delete().eq(_idColumn, id);
    } catch (error) {
      throw Exception('Error al eliminar la vacunación: $error');
    }
  }
  Future<List<VaccinationModel>> getVaccinationsForUser(
    String userId) async {

  final usuario = await _client
      .from('usuarios')
      .select('rol, sector_id')
      .eq('id', userId)
      .single();

  final rol = usuario['rol'];
  final sectorId = usuario['sector_id'];

  switch (rol) {
    case 'campana':
      return getVaccinations();

    case 'brigada':
      return getVaccinationsBySector(sectorId);

    case 'vacunador':
      return getVaccinationsByVaccinator(userId);

    default:
      return [];
  }
}
}

