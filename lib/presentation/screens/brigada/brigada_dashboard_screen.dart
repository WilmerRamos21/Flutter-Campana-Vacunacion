import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campaniia_vacunacion/data/models/vaccination_model.dart';
import 'package:campaniia_vacunacion/data/repositories/vaccination_repository.dart';



class BrigadaDashboardScreen extends StatefulWidget {
  const BrigadaDashboardScreen({super.key});

  @override
  State<BrigadaDashboardScreen> createState() => _BrigadaDashboardScreenState();
  
}


class _BrigadaDashboardScreenState extends State<BrigadaDashboardScreen> {
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

      if (date == null) {
        return false;
      }

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  void _goToCreateVaccinator(){
    Navigator.pushNamed(context, '/create-vaccinator');
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    // TODO: Reemplazar por la ruta real de login si tu proyecto usa otro nombre.
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
  void _goToSectorVaccinations() {
  Navigator.pushNamed(context, '/sector-vaccinations');
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de brigada'),
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

          return RefreshIndicator(
            onRefresh: _refreshVaccinations,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DashboardHeader(
                  totalVaccinations: vaccinations.length,
                  todayVaccinations: todayVaccinations,
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  title: 'Crear Vacunador',
                  subtitle: 'Agregar nuevo Vacunador',
                  icon: Icons.add_circle_outline,
                  onTap: _goToCreateVaccinator,
                ),
                const SizedBox(height: 8), // Espacio entre botones
                // NUEVO BOTÓN AGREGADO AQUÍ usando tu componente
                _ActionButton(
                  title: 'Editar registros del sector',
                  subtitle: 'Ver vacunaciones asignadas a mi sector',
                  icon: Icons.edit_note,
                  onTap: _goToSectorVaccinations,
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
                  ...vaccinations.map(
                    (vaccination) => _VaccinationCard(
                      vaccination: vaccination,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreateVaccinator,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.totalVaccinations,
    required this.todayVaccinations,
  });

  final int totalVaccinations;
  final int todayVaccinations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de jornada',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total',
                value: totalVaccinations.toString(),
                icon: Icons.vaccines,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
              'No se pudieron cargar las vacunaciones.',
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
