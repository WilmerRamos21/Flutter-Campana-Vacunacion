import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateBrigadeCoordinatorScreen extends StatefulWidget {
  const CreateBrigadeCoordinatorScreen({super.key});

  @override
  State<CreateBrigadeCoordinatorScreen> createState() =>
      _CreateBrigadeCoordinatorScreenState();
}

class _CreateBrigadeCoordinatorScreenState
    extends State<CreateBrigadeCoordinatorScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _cedulaController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  bool _isLoading = false;
  int? _selectedSectorId;

  static const String _defaultPassword = 'Ecuador2026';
  static const String _role = 'brigada';

  final List<int> _sectoresPermitidos = [1, 2, 3, 4, 5];

  Future<void> _createCoordinator() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSectorId == null) {
      _showMessage('Seleccione el sector del coordinador.');
      return;
    }

    if (_role != 'brigada') {
      _showMessage('Solo se permite crear usuarios con rol brigada.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await _supabase.auth.signUp(
        email: _correoController.text.trim(),
        password: _defaultPassword,
      );

      final authUser = authResponse.user;

      if (authUser == null) {
        throw Exception('No se pudo crear el usuario en Auth.');
      }

      await _supabase.from('usuarios').insert({
        'id': authUser.id,
        'cedula': _cedulaController.text.trim(),
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'correo': _correoController.text.trim(),
        'rol': _role,
        'sector_id': _selectedSectorId,
        'primer_ingreso': true,
      });

      if (!mounted) return;

      _showMessage('Coordinador de brigada creado correctamente.');
      _clearForm();
    } catch (error) {
      _showMessage('Error al crear coordinador: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _cedulaController.clear();
    _nombresController.clear();
    _apellidosController.clear();
    _telefonoController.clear();
    _correoController.clear();

    setState(() {
      _selectedSectorId = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese $fieldName.';
    }

    return null;
  }

  String? _validateCedula(String? value) {
    final cedula = value?.trim() ?? '';

    if (cedula.isEmpty) {
      return 'Ingrese la cédula.';
    }

    if (cedula.length != 10) {
      return 'La cédula debe tener 10 dígitos.';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(cedula)) {
      return 'La cédula solo debe contener números.';
    }

    return null;
  }

  String? _validateTelefono(String? value) {
    final telefono = value?.trim() ?? '';

    if (telefono.isEmpty) {
      return 'Ingrese el teléfono.';
    }

    if (telefono.length < 7 || telefono.length > 15) {
      return 'El teléfono debe tener entre 7 y 15 dígitos.';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(telefono)) {
      return 'El teléfono solo debe contener números.';
    }

    return null;
  }

  String? _validateCorreo(String? value) {
    final correo = value?.trim() ?? '';

    if (correo.isEmpty) {
      return 'Ingrese el correo.';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (!emailRegex.hasMatch(correo)) {
      return 'Ingrese un correo válido.';
    }

    return null;
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo coordinador de brigada'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.supervisor_account, size: 72),
                const SizedBox(height: 16),
                Text(
                  'Crear coordinador de brigada',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: _validateCedula,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombresController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateRequired(value, 'los nombres'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidosController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _validateRequired(value, 'los apellidos'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: _validateTelefono,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCorreo,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _role,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedSectorId,
                  decoration: const InputDecoration(
                    labelText: 'Sector asignado',
                    prefixIcon: Icon(Icons.map_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _sectoresPermitidos.map((sectorId) {
                    return DropdownMenuItem<int>(
                      value: sectorId,
                      child: Text('Sector $sectorId'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSectorId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Seleccione un sector.';
                    }

                    if (!_sectoresPermitidos.contains(value)) {
                      return 'El sector debe estar entre 1 y 5.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _createCoordinator,
                    icon: const Icon(Icons.save),
                    label: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear coordinador'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Contraseña inicial: Ecuador2026',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}