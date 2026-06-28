class VaccinationModel {
  final String? id;
  final String propietarioNombre;
  final String propietarioCedula;
  final String telefono;
  final String tipoMascota;
  final String nombreMascota;
  final String edadAproximada;
  final String sexo;
  final String vacunaAplicada;
  final String? observaciones;
  final String? fotoUrl;
  final double latitud;
  final double longitud;
  final DateTime? fechaHora;
  final String? vacunadorId;
  final int? sectorId;

  const VaccinationModel({
    this.id,
    required this.propietarioNombre,
    required this.propietarioCedula,
    required this.telefono,
    required this.tipoMascota,
    required this.nombreMascota,
    required this.edadAproximada,
    required this.sexo,
    required this.vacunaAplicada,
    this.observaciones,
    this.fotoUrl,
    required this.latitud,
    required this.longitud,
    this.fechaHora,
    this.vacunadorId,
    this.sectorId,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'] as String?,
      propietarioNombre: json['propietario_nombre'] as String,
      propietarioCedula: json['propietario_cedula'] as String,
      telefono: json['telefono'] as String,
      tipoMascota: json['tipo_mascota'] as String,
      nombreMascota: json['nombre_mascota'] as String,
      edadAproximada: json['edad_aproximada'] as String,
      sexo: json['sexo'] as String,
      vacunaAplicada: json['vacuna_aplicada'] as String,
      observaciones: json['observaciones'] as String?,
      fotoUrl: json['foto_url'] as String?,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      fechaHora: json['fecha_hora'] == null
          ? null
          : DateTime.parse(json['fecha_hora'] as String),
      vacunadorId: json['vacunador_id'] as String?,
      sectorId: json['sector_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'propietario_nombre': propietarioNombre,
      'propietario_cedula': propietarioCedula,
      'telefono': telefono,
      'tipo_mascota': tipoMascota,
      'nombre_mascota': nombreMascota,
      'edad_aproximada': edadAproximada,
      'sexo': sexo,
      'vacuna_aplicada': vacunaAplicada,
      'observaciones': observaciones,
      'foto_url': fotoUrl,
      'latitud': latitud,
      'longitud': longitud,
      if (fechaHora != null) 'fecha_hora': fechaHora!.toIso8601String(),
      'vacunador_id': vacunadorId,
      'sector_id': sectorId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final data = toJson();
    data.remove('id');
    return data;
  }
}