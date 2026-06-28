class UserModel {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String rol; // 'campana', 'brigada', 'vacunador'
  final int? sectorId;
  final bool primerIngreso;

  UserModel({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.rol,
    this.sectorId,
    required this.primerIngreso,
  });

  // Convierte el JSON que responde Supabase a un objeto de Flutter
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      cedula: json['cedula'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      rol: json['rol'] ?? 'vacunador',
      sectorId: json['sector_id'],
      primerIngreso: json['primer_ingreso'] ?? true,
    );
  }
}