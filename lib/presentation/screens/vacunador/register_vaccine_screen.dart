import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../state/sync_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campaniia_vacunacion/data/repositories/user_repository.dart';

class RegisterVaccineScreen extends StatefulWidget {
  
  const RegisterVaccineScreen({super.key});
  
  

  @override
  State<RegisterVaccineScreen> createState() => _RegisterVaccineScreenState();
}

class _RegisterVaccineScreenState extends State<RegisterVaccineScreen> {
  // Controladores de texto para el formulario
  final _nombrePropietarioCtrl = TextEditingController();
  final _nombreMascotaCtrl = TextEditingController();
  final _propietarioCedulaCtrl = TextEditingController();
  final _propietarioTelefono = TextEditingController();
  final _edadAproximadaCtrl = TextEditingController();
  final _vacunaAplicadaCtrl = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  


  String? _tipoMascota;
  String? _sexo;

  // Variables de hardware
  File? _imagenMascota;
  Position? _posicionActual;
  bool _obteniendoUbicacion = false;

  final List<String> _tiposMascota = ['perro', 'gato'];
  final List<String> _sexos = ['macho', 'hembra'];


  @override
  void initState() {
    super.initState();
    _capturarGPSAutomatico(); // <-- Se ejecuta apenas se abre la pantalla
    // Encender el vigilante de internet
    SyncService().listenToConnectionChanges();
  }

  Future<void> _capturarGPSAutomatico() async {
    setState(() => _obteniendoUbicacion = true);

    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verifica si el GPS del iPhone está encendido
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Manejar error: Pedir al usuario que encienda el GPS
      setState(() => _obteniendoUbicacion = false);
      return;
    }

    // 2. Verifica los permisos de la app
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _obteniendoUbicacion = false);
        return; // Permiso denegado
      }
    }

    // 3. Obtiene la latitud y longitud con alta precisión
    Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _posicionActual = posicion;
      _obteniendoUbicacion = false;
    });
  }
  Future<void> _tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    // Usa ImageSource.camera para abrir la cámara nativa
    final XFile? foto = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // Comprimir al 70% para no saturar el storage
    );

    if (foto != null) {
      setState(() {
        _imagenMascota = File(foto.path);
      });
    }
  }
Future<void> _guardarRegistro() async {
  if (_imagenMascota == null || _posicionActual == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Falta la fotografía o la ubicación')),
    );
    return;
  }

  final connectivityResult = await Connectivity().checkConnectivity();
  final isOffline = connectivityResult.contains(ConnectivityResult.none);
  final user = Supabase.instance.client.auth.currentUser;

if (user == null) {
  throw Exception('Usuario no autenticado');
}

final sectorId =
    await _userRepository.getUserSector(user.id);

  if (isOffline) {
    final mapaVacunacion = {
      'propietario_nombre': _nombrePropietarioCtrl.text.trim(),
      'propietario_cedula': _propietarioCedulaCtrl.text.trim(),
      'telefono': _propietarioTelefono.text.trim(),
      'nombre_mascota': _nombreMascotaCtrl.text.trim(),
      'tipo_mascota': _tipoMascota,
      'edad_aproximada': _edadAproximadaCtrl.text.trim(),
      'sexo': _sexo,
      'vacuna_aplicada': _vacunaAplicadaCtrl.text.trim(),
      'latitud': _posicionActual!.latitude,
      'longitud': _posicionActual!.longitude,
      'foto_path': _imagenMascota!.path,
      'sincronizado': false,
      'fecha_hora': DateTime.now().toIso8601String(),
      'sector_id': sectorId,
    };

    final box = Hive.box('vacunaciones_offline');
    await box.add(mapaVacunacion);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sin conexión. Guardado localmente para sincronizar luego.'),
      ),
    );

    _limpiarFormulario();
    return;
  }

  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No existe un usuario autenticado.');
    }
    final sectorId = await _userRepository.getUserSector(user.id);

    if (sectorId == null) {
      throw Exception(
          'El usuario no tiene un sector asignado.');
    }

    final extension = _imagenMascota!.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$extension';
    final storagePath = 'vacunaciones/${user.id}/$fileName';

    await supabase.storage.from('mascotas').upload(
          storagePath,
          _imagenMascota!,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    final fotoUrl = supabase.storage.from('mascotas').getPublicUrl(storagePath);

    await supabase.from('vacunaciones').insert({
      'propietario_nombre': _nombrePropietarioCtrl.text.trim(),
      'nombre_mascota': _nombreMascotaCtrl.text.trim(),
      'propietario_cedula': _propietarioCedulaCtrl.text.trim(),
      'telefono': _propietarioTelefono.text.trim(),
      'tipo_mascota': _tipoMascota,
      'edad_aproximada': _edadAproximadaCtrl.text.trim(),
      'sexo': _sexo,
      'vacuna_aplicada': _vacunaAplicadaCtrl.text.trim(),
      'latitud': _posicionActual!.latitude,
      'longitud': _posicionActual!.longitude,
      'foto_url': fotoUrl,
      'fecha_hora': DateTime.now().toIso8601String(),
      'vacunador_id': user.id,
      'sector_id': sectorId,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro guardado en la nube con éxito.')),
    );

    _limpiarFormulario();
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al guardar registro: $error')),
    );
  }
}
  @override
    void dispose() {
      _nombrePropietarioCtrl.dispose();
      _nombreMascotaCtrl.dispose();
      _propietarioCedulaCtrl.dispose();
      _propietarioTelefono.dispose();
      _edadAproximadaCtrl.dispose();
      _vacunaAplicadaCtrl.dispose();
      super.dispose();
    }

    void _limpiarFormulario() {
      _nombrePropietarioCtrl.clear();
      _nombreMascotaCtrl.clear();
      _propietarioCedulaCtrl.clear();
      _propietarioTelefono.clear();
      _edadAproximadaCtrl.clear();
      _vacunaAplicadaCtrl.clear();

      setState(() {
        _imagenMascota = null;
        _tipoMascota = null;
        _sexo = null;
      });
    }
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Vacunación'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECCIÓN: DATOS DEL PROPIETARIO ---
            Text(
              'Datos del Propietario',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _propietarioCedulaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cédula',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombrePropietarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _propietarioTelefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 32),

            // --- SECCIÓN: DATOS DE LA MASCOTA ---
            Text(
              'Datos de la Mascota',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreMascotaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Mascota',
                prefixIcon: Icon(Icons.pets),
                border: OutlineInputBorder(),
              ),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _edadAproximadaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Edad aprox.',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                      suffixText: 'meses/años',
                    ),
                  ),
                ),
              ],
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
            const Divider(height: 32),

            // --- SECCIÓN: DATOS DE LA VACUNA ---
            Text(
              'Datos Médicos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vacunaAplicadaCtrl,
              decoration: const InputDecoration(
                labelText: 'Vacuna Aplicada (Ej. Antirrábica)',
                prefixIcon: Icon(Icons.vaccines),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECCIÓN: HARDWARE Y UBIACIÓN ---
            // Indicador de GPS
            Card(
              color: _posicionActual != null ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _obteniendoUbicacion
                    ? const Row(
                        children: [
                          CircularProgressIndicator.adaptive(),
                          SizedBox(width: 12),
                          Text('Obteniendo coordenadas GPS...'),
                        ],
                      )
                    : Text(_posicionActual != null
                        ? '📍 Ubicación capturada: \nLat: ${_posicionActual!.latitude} \nLng: ${_posicionActual!.longitude}'
                        : '⚠️ Esperando señal de GPS...'),
              ),
            ),
            const SizedBox(height: 20),

            // Vista previa de la Imagen
            Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _imagenMascota != null
                  ? Image.file(_imagenMascota!, fit: BoxFit.cover)
                  : const Center(child: Text('No hay fotografía capturada')),
            ),
            const SizedBox(height: 12),

            // Botón para abrir la cámara
            ElevatedButton.icon(
              onPressed: _tomarFoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar Foto de la Mascota'),
            ),
            const SizedBox(height: 30),

            // Botón principal de guardado
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _guardarRegistro,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Guardar Registro',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30), // Margen inferior extra para que no pegue con el teclado
          ],
        ),
      ),
    );
  }
}