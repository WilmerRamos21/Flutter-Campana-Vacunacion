import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campaniia_vacunacion/data/models/vaccination_model.dart';
import 'package:campaniia_vacunacion/data/repositories/vaccination_repository.dart';


class EditVaccinatorRecordScreen extends StatefulWidget {
  const EditVaccinatorRecordScreen({
    super.key,
    required this.vaccinationId,
  });

  final String vaccinationId;

  @override
  State<EditVaccinatorRecordScreen> createState() =>
      _EditVaccinatorRecordScreenState();
}

class _EditVaccinatorRecordScreenState
    extends State<EditVaccinatorRecordScreen> {
  final _repository = VaccinationRepository();
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _propietarioNombreCtrl = TextEditingController();
  final _propietarioCedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _nombreMascotaCtrl = TextEditingController();
  final _edadAproximadaCtrl = TextEditingController();
  final _vacunaAplicadaCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  VaccinationModel? _vaccination;
  int? _userSectorId; // Cambiado para reflejar el sector del vacunador

  String? _tipoMascota;
  String? _sexo;

  // Variables de Hardware
  File? _nuevaFoto;
  Position? _nuevaPosicion;
  bool _obteniendoUbicacion = false;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _tiposMascota = ['perro', 'gato'];
  final List<String> _sexos = ['macho', 'hembra'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('No existe un usuario autenticado.');
      }

      // Obtenemos el sector del vacunador actual
      final userData = await _supabase
          .from('usuarios')
          .select('sector_id')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userData == null || userData['sector_id'] == null) {
        throw Exception('El vacunador no tiene un sector asignado.');
      }

      final currentSectorId = userData['sector_id'] as int;

      final vaccination =
          await _repository.getVaccinationById(widget.vaccinationId);

      if (vaccination == null) {
        throw Exception('No se encontró el registro de vacunación.');
      }

      // Validación clave: El vacunador solo puede editar si el registro es de su mismo sector
      if (vaccination.sectorId != currentSectorId) {
        throw Exception(
          'No tienes permiso para editar registros de otro sector.',
        );
      }

      _userSectorId = currentSectorId;
      _vaccination = vaccination;

      _propietarioNombreCtrl.text = vaccination.propietarioNombre;
      _propietarioCedulaCtrl.text = vaccination.propietarioCedula;
      _telefonoCtrl.text = vaccination.telefono;
      _nombreMascotaCtrl.text = vaccination.nombreMascota;
      _edadAproximadaCtrl.text = vaccination.edadAproximada;
      _vacunaAplicadaCtrl.text = vaccination.vacunaAplicada;
      _observacionesCtrl.text = vaccination.observaciones ?? '';

      _tipoMascota = vaccination.tipoMascota.trim().toLowerCase();
      _sexo = vaccination.sexo.trim().toLowerCase();

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
    _actualizarUbicacion();
  }
  Future<void> _actualizarUbicacion() async {
    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados.');
      }

      // 2. Verificar y solicitar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Los permisos de ubicación fueron denegados.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Los permisos de ubicación están denegados permanentemente.');
      }

      // 3. Obtener la posición actual
      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _nuevaPosicion = posicion;
        _obteniendoUbicacion = false;
      });
    } catch (e) {
      setState(() {
        _obteniendoUbicacion = false;
      });
      // Opcional: Mostrar un SnackBar con el error de por qué no se pudo obtener
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la ubicación: $e')),
      );
    }
  }
Future<void> _tomarNuevaFoto() async {
  final picker = ImagePicker();

  final foto = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 70,
  );

  if (foto != null) {
    setState(() {
      _nuevaFoto = File(foto.path);
    });
  }
}

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_vaccination == null || _userSectorId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });
    String fotoUrl = _vaccination!.fotoUrl ?? '';
        if (_nuevaFoto != null) {
      final extension = _nuevaFoto!.path.split('.').last;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      final storagePath =
          'vacunaciones/${_vaccination!.vacunadorId}/$fileName';

      await _supabase.storage
          .from('mascotas')
          .upload(storagePath, _nuevaFoto!);

      fotoUrl = _supabase.storage
          .from('mascotas')
          .getPublicUrl(storagePath);
    }
    try {
      final updatedVaccination = VaccinationModel(
        id: _vaccination!.id,
        propietarioNombre: _propietarioNombreCtrl.text.trim(),
        propietarioCedula: _propietarioCedulaCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        tipoMascota: _tipoMascota!,
        nombreMascota: _nombreMascotaCtrl.text.trim(),
        edadAproximada: _edadAproximadaCtrl.text.trim(),
        sexo: _sexo!,
        vacunaAplicada: _vacunaAplicadaCtrl.text.trim(),
        observaciones: _observacionesCtrl.text.trim().isEmpty
            ? null
            : _observacionesCtrl.text.trim(),
        fotoUrl: fotoUrl,
        latitud: _nuevaPosicion?.latitude ??
            _vaccination!.latitud,

        longitud: _nuevaPosicion?.longitude ??
            _vaccination!.longitud,
        fechaHora: _vaccination!.fechaHora,
        vacunadorId: _vaccination!.vacunadorId, // Mantiene el ID de quien lo creó originalmente
        sectorId: _userSectorId,
      );

      await _repository.updateVaccination(updatedVaccination);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro actualizado correctamente.')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _propietarioNombreCtrl.dispose();
    _propietarioCedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _nombreMascotaCtrl.dispose();
    _edadAproximadaCtrl.dispose();
    _vacunaAplicadaCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar registro'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar mi vacunación'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _propietarioNombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del propietario',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _propietarioCedulaCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Cédula del propietario',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _tipoMascota,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de mascota',
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposMascota.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoMascota = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Seleccione el tipo de mascota.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreMascotaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la mascota',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _edadAproximadaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Edad aproximada',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _sexo,
                  decoration: const InputDecoration(
                    labelText: 'Sexo',
                    border: OutlineInputBorder(),
                  ),
                  items: _sexos.map((sexo) {
                    return DropdownMenuItem(
                      value: sexo,
                      child: Text(sexo),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sexo = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Seleccione el sexo.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vacunaAplicadaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vacuna aplicada',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _obteniendoUbicacion || _isSaving
                      ? null
                      : _actualizarUbicacion,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Actualizar ubicación'),
                ),
                Card(
                  color: _obteniendoUbicacion ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _obteniendoUbicacion
                        ? const Row(
                            children: [
                              CircularProgressIndicator.adaptive(),
                              SizedBox(width: 12),
                              Text('Actualizando ubicación...'),
                            ],
                          )
                        : Text(_nuevaPosicion != null
                                ? '📍 Nueva ubicación capturada: \nLat: ${_nuevaPosicion!.latitude} \nLng: ${_nuevaPosicion!.longitude}'
                                : '⚠️ Usando ubicación original',
                          ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _tomarNuevaFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cambiar foto'),
                ),
                if (_nuevaFoto != null)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    child: Image.file(
                      _nuevaFoto!,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveChanges,
                    icon: const Icon(Icons.save),
                    label: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio.';
    }

    return null;
  }
}