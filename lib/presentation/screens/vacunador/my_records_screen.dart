import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Rutas absolutas igual que en tu Dashboard
import 'package:campaniia_vacunacion/data/models/vaccination_model.dart';
import 'package:campaniia_vacunacion/data/repositories/vaccination_repository.dart';

class MyRecordsScreen extends StatefulWidget {
  const MyRecordsScreen({super.key});

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  final VaccinationRepository _vaccinationRepository = VaccinationRepository();

  late Future<List<VaccinationModel>> _vaccinationsFuture;

  @override
  void initState() {
    super.initState();
    _vaccinationsFuture = _loadVaccinations();
  }

  Future<List<VaccinationModel>> _loadVaccinations() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('No existe un usuario autenticado.');
    }

    return _vaccinationRepository.getVaccinationsForUser(user.id);
  }

  Future<void> _refreshVaccinations() async {
    setState(() {
      _vaccinationsFuture = _loadVaccinations();
    });

    await _vaccinationsFuture;
  }

  int _countTodayVaccinations(List<VaccinationModel> vaccinations) {
    final now = DateTime.now();

    return vaccinations.where((vaccination) {
      final date = vaccination.fechaHora;

      if (date == null) return false;

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis registros'),
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
          final todayVaccinations = _countTodayVaccinations(vaccinations);

          return RefreshIndicator(
            onRefresh: _refreshVaccinations,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryHeader(
                  totalVaccinations: vaccinations.length,
                  todayVaccinations: todayVaccinations,
                ),
                const SizedBox(height: 24),
                Text(
                  'Historial de vacunaciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (vaccinations.isEmpty)
                  const _EmptyState()
                else
                  ...vaccinations.map(
                    (vaccination) => _VaccinationRecordCard(vaccination: vaccination),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalVaccinations,
    required this.todayVaccinations,
  });

  final int totalVaccinations;
  final int todayVaccinations;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total',
            value: totalVaccinations.toString(),
            icon: Icons.assignment,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Hoy',
            value: todayVaccinations.toString(),
            icon: Icons.today,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _VaccinationRecordCard extends StatelessWidget {
  const _VaccinationRecordCard({
    required this.vaccination,
  });

  final VaccinationModel vaccination;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            // Corregido a 'perro' en lugar de 'canino'
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
            Text('Tipo: ${vaccination.tipoMascota}'),
            if (vaccination.fechaHora != null)
              Text('Fecha: ${_formatDate(vaccination.fechaHora!)}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            builder: (_) => _RecordDetails(vaccination: vaccination),
          );
        },
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

class _RecordDetails extends StatelessWidget {
  const _RecordDetails({
    required this.vaccination,
  });

  final VaccinationModel vaccination;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vaccination.nombreMascota,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Propietario', value: vaccination.propietarioNombre),
            _DetailRow(label: 'Cédula', value: vaccination.propietarioCedula),
            _DetailRow(label: 'Teléfono', value: vaccination.telefono),
            _DetailRow(label: 'Tipo de mascota', value: vaccination.tipoMascota),
            _DetailRow(label: 'Edad aproximada', value: vaccination.edadAproximada),
            _DetailRow(label: 'Sexo', value: vaccination.sexo),
            _DetailRow(label: 'Vacuna', value: vaccination.vacunaAplicada),
            if (vaccination.observaciones != null &&
                vaccination.observaciones!.trim().isNotEmpty)
              _DetailRow(label: 'Observaciones', value: vaccination.observaciones!),
            _DetailRow(label: 'Latitud', value: vaccination.latitud.toString()),
            _DetailRow(label: 'Longitud', value: vaccination.longitud.toString()),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text('$label: $value'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Aún no tienes vacunaciones registradas.'),
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
              'No se pudieron cargar tus registros.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
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