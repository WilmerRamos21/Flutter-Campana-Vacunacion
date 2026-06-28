import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Función para iniciar sesión
  Future<UserModel?> login(String email, String password) async {
    try {
      // 1. Autentica las credenciales en el sistema central
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // 2. Busca los datos obligatorios de la rúbrica (cédula, rol) en la tabla pública
        final data = await _supabase
            .from('usuarios')
            .select()
            .eq('id', res.user!.id)
            .single();
        
        return UserModel.fromJson(data);
      }
    } catch (e) {
      print("Error en login: $e");
      rethrow; // Para manejar el estado de error en la UI
    }
    return null;
  }
  
}
