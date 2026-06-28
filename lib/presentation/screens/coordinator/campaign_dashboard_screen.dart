
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/vaccination_model.dart';
import '../../../data/repositories/vaccination_repository.dart';

class CampaignDashboardScreen extends StatefulWidget {
  const CampaignDashboardScreen({super.key});

  @override
  State<CampaignDashboardScreen> createState() =>
      _CampaignDashboardScreenState();
}

class _CampaignDashboardScreenState extends State<CampaignDashboardScreen> {
  final VaccinationRepository _vaccinationRepository = VaccinationRepository();

  late Future<List<VaccinationModel>> _vaccinationsFuture;

  @override
  void initState() {
    super.initState();
    _vaccinationsFuture = _loadVaccinations();
  }

  Future<List<VaccinationModel>> _loadVaccinations() {
    return _vaccinationRepository.getVaccinations();
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

      if (date == null) {
        return false;
      }

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int _countByPetType(
    List<VaccinationModel> vaccinations,
    String petType,
  ) {
    return vaccinations.where((vaccination) {
      return vaccination.tipoMascota.toLowerCase() == petType.toLowerCase();
    }).length;
  }

  int _countCoveredSectors(List<VaccinationModel> vaccinations) {
    final sectors = vaccinations
        .map((vaccination) => vaccination.sectorId)
        .whereType<int>()
        .toSet();

    return sectors.length;
  }

  void _goToVaccinationList() {
    // TODO: Reemplazar por la ruta real cuando exista la pantalla de listado.
    Navigator.pushNamed(context, '/vaccinations');
  }

  void _goToReports() {
    // TODO: Reemplazar por la ruta real cuando exista la pantalla de reportes.
    Navigator.pushNamed(context, '/campaign-reports');
  }

  void _goToCreateCoordinadorbrigade(){
    Navigator.pushNamed(context, '/create-brigade-coordinator');
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    // TODO: Reemplazar por la ruta real de login si tu proyecto usa otro nombre.
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de campaña'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<VaccinationModel>>(
        future: _vaccinationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refreshVaccinations,
            );
          }

          final vaccinations = snapshot.data ?? <VaccinationModel>[];

          final todayVaccinations = _countTodayVaccinations(vaccinations);
          final canineVaccinations = _countByPetType(vaccinations, 'perro');
          final felineVaccinations = _countByPetType(vaccinations, 'gato');
          final coveredSectors = _countCoveredSectors(vaccinations);

          return RefreshIndicator(
            onRefresh: _refreshVaccinations,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Resumen general',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _StatsGrid(
                  totalVaccinations: vaccinations.length,
                  todayVaccinations: todayVaccinations,
                  canineVaccinations: canineVaccinations,
                  felineVaccinations: felineVaccinations,
                  coveredSectors: coveredSectors,
                ),
                const SizedBox(height: 24),
                _DashboardAction(
                  title: 'Ver vacunaciones',
                  subtitle: 'Consultar todos los registros de la campaña',
                  icon: Icons.list_alt,
                  onTap: _goToVaccinationList,
                ),
                const SizedBox(height: 12),
                _DashboardAction(
                  title: 'Reportes',
                  subtitle: 'Revisar estadísticas y avances de campaña',
                  icon: Icons.bar_chart,
                  onTap: _goToReports,
                ),
                const SizedBox(height: 16),
                _DashboardAction(
                  title: 'Crear Coordinador de Brigada',
                  subtitle: 'Agregar nuevo coordinador de brigada',
                  icon: Icons.add_circle_outline,
                  onTap: _goToCreateCoordinadorbrigade,
                ),
                const SizedBox(height: 24),
                Text(
                  'Últimos registros',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (vaccinations.isEmpty)
                  const _EmptyState()
                else
                  ...vaccinations.take(10).map(
                        (vaccination) => _VaccinationCard(
                          vaccination: vaccination,
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalVaccinations,
    required this.todayVaccinations,
    required this.canineVaccinations,
    required this.felineVaccinations,
    required this.coveredSectors,
  });

  final int totalVaccinations;
  final int todayVaccinations;
  final int canineVaccinations;
  final int felineVaccinations;
  final int coveredSectors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total',
                value: totalVaccinations.toString(),
                icon: Icons.vaccines,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Hoy',
                value: todayVaccinations.toString(),
                icon: Icons.today,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Caninos',
                value: canineVaccinations.toString(),
                icon: Icons.pets,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Felinos',
                value: felineVaccinations.toString(),
                icon: Icons.cruelty_free,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'Sectores cubiertos',
          value: coveredSectors.toString(),
          icon: Icons.map,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _VaccinationCard extends StatelessWidget {
  const _VaccinationCard({
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
            if (vaccination.sectorId != null)
              Text('Sector: ${vaccination.sectorId}'),
            if (vaccination.fechaHora != null)
              Text('Fecha: ${_formatDate(vaccination.fechaHora!)}'),
          ],
        ),
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
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Aún no hay vacunaciones registradas.'),
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
              'No se pudo cargar el panel de campaña.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
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