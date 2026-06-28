import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/vaccination_model.dart';
import '../../../data/repositories/vaccination_repository.dart';
import '../vacunador//edit_vaccinator_screen.dart';

class VacunadorSectorVaccinationsScreen extends StatefulWidget {
  const VacunadorSectorVaccinationsScreen({super.key});

  @override
  State<VacunadorSectorVaccinationsScreen> createState() =>
      _VacunadorSectorVaccinationsScreenState();
}

class _VacunadorSectorVaccinationsScreenState
    extends State<VacunadorSectorVaccinationsScreen> {
  final _supabase = Supabase.instance.client;
  final _repository = VaccinationRepository();

  late Future<List<VaccinationModel>> _vaccinationsFuture;
  int? _sectorId;

  @override
  void initState() {
    super.initState();
    _vaccinationsFuture = _loadSectorVaccinations();
  }

  Future<List<VaccinationModel>> _loadSectorVaccinations() async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('No existe un usuario autenticado.');
    }

    // Buscamos el sector del vacunador actual
    final userData = await _supabase
        .from('usuarios')
        .select('sector_id')
        .eq('id', currentUser.id)
        .maybeSingle();

    if (userData == null || userData['sector_id'] == null) {
      throw Exception('El vacunador no tiene sector asignado.');
    }

    final sectorId = userData['sector_id'] as int;
    _sectorId = sectorId;

    // Retorna las vacunaciones de ese sector
    return _repository.getVaccinationsBySector(sectorId);
  }

  Future<void> _refreshVaccinations() async {
    setState(() {
      _vaccinationsFuture = _loadSectorVaccinations();
    });
    await _vaccinationsFuture;
  }

  Future<void> _openEditScreen(VaccinationModel vaccination) async {
    final vaccinationId = vaccination.id;

    if (vaccinationId == null || vaccinationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El registro no tiene ID válido.')),
      );
      return;
    }

    // IMPORTANTE: Aquí se pasa el ID directamente de forma dinámica al hacer tap
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditVaccinatorRecordScreen(
          vaccinationId: vaccinationId,
        ),
      ),
    );

    if (updated == true) {
      _refreshVaccinations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _sectorId == null
        ? 'Registros del sector'
        : 'Registros del sector $_sectorId';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<VaccinationModel>>(
        future: _vaccinationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refreshVaccinations,
            );
          }

          final vaccinations = snapshot.data ?? <VaccinationModel>[];

          if (vaccinations.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshVaccinations,
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  _EmptyState(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshVaccinations,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vaccinations.length,
              itemBuilder: (context, index) {
                final vaccination = vaccinations[index];

                return _VaccinationTile(
                  vaccination: vaccination,
                  onTap: () => _openEditScreen(vaccination),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- SUB-WIDGETS COMPONENTES ---

class _VaccinationTile extends StatelessWidget {
  const _VaccinationTile({
    required this.vaccination,
    required this.onTap,
  });

  final VaccinationModel vaccination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fecha = vaccination.fechaHora == null
        ? 'Sin fecha'
        : _formatDate(vaccination.fechaHora!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Icon(
            vaccination.tipoMascota.toLowerCase() == 'perro'
                ? Icons.pets
                : Icons.cruelty_free,
          ),
        ),
        title: Text(vaccination.nombreMascota),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propietario: ${vaccination.propietarioNombre}'),
            Text('Vacuna: ${vaccination.vacunaAplicada}'),
            Text('Fecha: $fecha'),
          ],
        ),
        trailing: const Icon(Icons.edit),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay vacunaciones registradas en tu sector.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron cargar las vacunaciones.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}