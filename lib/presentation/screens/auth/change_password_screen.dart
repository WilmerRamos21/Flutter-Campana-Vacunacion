import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importa tus modelos y pantallas (Ajusta las rutas según tu proyecto)
import '../../../data/models/user_model.dart';
import '../coordinator/campaign_dashboard_screen.dart';
import '../brigada/brigada_dashboard_screen.dart';
import '../vacunador/register_vaccine_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final UserModel usuario; // Necesitamos saber quién está cambiando la clave

  const ChangePasswordScreen({super.key, required this.usuario});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _supabase = Supabase.instance.client;
  final _nuevaClaveCtrl = TextEditingController();
  final _confirmarClaveCtrl = TextEditingController();
  
  bool _isObscure = true;
  bool _isLoading = false;

  Future<void> _actualizarContrasena() async {
    final nuevaClave = _nuevaClaveCtrl.text.trim();
    final confirmarClave = _confirmarClaveCtrl.text.trim();

    // 1. Validaciones básicas
    if (nuevaClave.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }
    if (nuevaClave != confirmarClave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Actualizar la contraseña en Supabase Auth
      await _supabase.auth.updateUser(
        UserAttributes(password: nuevaClave),
      );

      // 3. Actualizar la bandera "primer_ingreso" en la tabla pública usuarios
      await _supabase
          .from('usuarios')
          .update({'primer_ingreso': false})
          .eq('id', widget.usuario.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada con éxito')),
      );

      // 4. Redirigir al Dashboard correcto según su rol
      Widget pantallaDestino;
      switch (widget.usuario.rol) {
        case 'campana':
          pantallaDestino = const CampaignDashboardScreen();
          break;
        case 'brigada':
          pantallaDestino = const BrigadaDashboardScreen();
          break;
        case 'vacunador':
        default:
          pantallaDestino = const RegisterVaccineScreen();
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => pantallaDestino),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nuevaClaveCtrl.dispose();
    _confirmarClaveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambio Obligatorio de Clave'),
        // Evitamos que el usuario regrese atrás sin cambiar la clave
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              const Icon(
                Icons.security,
                size: 80,
                color: Colors.teal,
              ),

              const SizedBox(height: 20),

              const Text(
                'Por seguridad, debes cambiar tu contraseña inicial (Ecuador2026) antes de continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _nuevaClaveCtrl,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _isObscure = !_isObscure),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _confirmarClaveCtrl,
                obscureText: _isObscure,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isLoading
                    ? null
                    : _actualizarContrasena,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar y Continuar',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}