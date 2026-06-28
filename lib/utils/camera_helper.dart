import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CameraHelper {
  CameraHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Abre la cámara del dispositivo y retorna la imagen capturada.
  static Future<XFile?> takePhoto() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1280,
      );
    } catch (error) {
      throw Exception('Error al abrir la cámara: $error');
    }
  }

  /// Abre la galería del dispositivo y retorna la imagen seleccionada.
  static Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1280,
      );
    } catch (error) {
      throw Exception('Error al seleccionar imagen: $error');
    }
  }

  /// Sube una imagen al Storage de Supabase y retorna la URL pública.
  ///
  /// Debes enviar el nombre real del bucket creado en Supabase.
  static Future<String> uploadPhoto({
    required XFile image,
    required String bucketName,
    String folderName = 'vacunaciones',
  }) async {
    try {
      final file = File(image.path);
      final extension = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = '$folderName/$fileName';

      await Supabase.instance.client.storage.from(bucketName).upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      return Supabase.instance.client.storage.from(bucketName).getPublicUrl(path);
    } catch (error) {
      throw Exception('Error al subir la foto: $error');
    }
  }
}