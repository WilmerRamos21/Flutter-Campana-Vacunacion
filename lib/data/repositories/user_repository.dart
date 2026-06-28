import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  UserRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<int?> getUserSector(String userId) async {
    final usuario = await _client
        .from('usuarios')
        .select('sector_id')
        .eq('id', userId)
        .single();

    return usuario['sector_id'] as int?;
  }
}