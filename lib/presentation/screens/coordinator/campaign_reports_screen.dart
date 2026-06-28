import 'package:flutter/material.dart';

import '../../../data/models/vaccination_model.dart';
import '../../../data/repositories/vaccination_repository.dart';

class CampaignReportsScreen extends StatefulWidget {
  const CampaignReportsScreen({super.key});

  @override
  State<CampaignReportsScreen> createState() => _CampaignReportsScreenState();
}

class _CampaignReportsScreenState extends State<CampaignReportsScreen> {
  final VaccinationRepository _repository = VaccinationRepository();

  late Future<List<VaccinationModel>> _vaccinationsFuture;

  @override
  void initState() {
    super.initState();
    _vaccinationsFuture = _repository.getVaccinations();
  }

  Future<void> _refreshReports() async {
    setState(() {
      _vaccinationsFuture = _repository.getVaccinations();
    });

    await _vaccinationsFuture;
  }

  int _countToday(List<VaccinationModel> vaccinations) {
    final now = DateTime.now();

    return vaccinations.where((vaccination) {
      final date = vaccination.fechaHora;

      if (date == null) return false;

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int _countByPetType(List<VaccinationModel> vaccinations, String type) {
    return vaccinations.where((vaccination) {
      return vaccination.tipoMascota.toLowerCase() == type.toLowerCase();
    }).length;
  }

  int _countBySex(List<VaccinationModel> vaccinations, String sex) {
    return vaccinations.where((vaccination) {
      return vaccination.sexo.toLowerCase() == sex.toLowerCase();
    }).length;
  }

  int _countSectors(List<VaccinationModel> vaccinations) {
    return vaccinations
        .map((vaccination) => vaccination.sectorId)
        .whereType<int>()
        .toSet()
        .length;
  }

  Map<int, int> _countBySector(List<VaccinationModel> vaccinations) {
    final result = <int, int>{};

    for (final vaccination in vaccinations) {
      final sectorId = vaccination.sectorId;

      if (sectorId == null) continue;

      result[sectorId] = (result[sectorId] ?? 0) + 1;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de campaña'),
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
              onRetry: _refreshReports,
            );
          }

          final vaccinations = snapshot.data ?? <VaccinationModel>[];

          final total = vaccinations.length;
          final today = _countToday(vaccinations);
          final caninos = _countByPetType(vaccinations, 'perro');
          final felinos = _countByPetType(vaccinations, 'gato');
          final machos = _countBySex(vaccinations, 'macho');
          final hembras = _countBySex(vaccinations, 'hembra');
          final sectores = _countSectors(vaccinations);
          final bySector = _countBySector(vaccinations);

          return RefreshIndicator(
            onRefresh: _refreshReports,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Resumen estadístico',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _ReportGrid(
                  total: total,
                  today: today,
                  caninos: caninos,
                  felinos: felinos,
                  machos: machos,
                  hembras: hembras,
                  sectores: sectores,
                ),
                const SizedBox(height: 24),
                Text(
                  'Vacunaciones por sector',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (bySector.isEmpty)
                  const _EmptyState()
                else
                  ...bySector.entries.map(
                    (entry) => _SectorReportTile(
                      sectorId: entry.key,
                      total: entry.value,
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

class _ReportGrid extends StatelessWidget {
  const _ReportGrid({
    required this.total,
    required this.today,
    required this.caninos,
    required this.felinos,
    required this.machos,
    required this.hembras,
    required this.sectores,
  });

  final int total;
  final int today;
  final int caninos;
  final int felinos;
  final int machos;
  final int hembras;
  final int sectores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReportCard(
                title: 'Total',
                value: total.toString(),
                icon: Icons.vaccines,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportCard(
                title: 'Hoy',
                value: today.toString(),
                icon: Icons.today,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ReportCard(
                title: 'Caninos',
                value: caninos.toString(),
                icon: Icons.pets,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportCard(
                title: 'Felinos',
                value: felinos.toString(),
                icon: Icons.cruelty_free,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ReportCard(
                title: 'Machos',
                value: machos.toString(),
                icon: Icons.male,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportCard(
                title: 'Hembras',
                value: hembras.toString(),
                icon: Icons.female,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ReportCard(
          title: 'Sectores cubiertos',
          value: sectores.toString(),
          icon: Icons.map,
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
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
            Icon(icon, size: 30),
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

class _SectorReportTile extends StatelessWidget {
  const _SectorReportTile({
    required this.sectorId,
    required this.total,
  });

  final int sectorId;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text('Sector $sectorId'),
        trailing: Text(
          total.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
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
          child: Text('Aún no hay datos para generar reportes.'),
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
              'No se pudieron cargar los reportes.',
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