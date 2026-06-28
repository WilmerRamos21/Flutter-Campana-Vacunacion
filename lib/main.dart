import 'package:campaniia_vacunacion/presentation/screens/brigada/brigada_dashboard_screen.dart';
import 'package:campaniia_vacunacion/presentation/screens/coordinator/campaign_reports_screen.dart';
import 'package:campaniia_vacunacion/presentation/screens/vacunador/my_records_screen.dart';
import 'package:campaniia_vacunacion/presentation/screens/vacunador/register_vaccine_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campaniia_vacunacion/presentation/screens/coordinator/create_brigade_coordinator_screen.dart';
import 'package:campaniia_vacunacion/presentation/screens/brigada/create_vaccinator_screen.dart';
import 'package:campaniia_vacunacion/presentation/screens/brigada/sector_vaccinations_screen.dart';
import 'package:campaniia_vacunacion/presentation/screens/vacunador/vacunador_sector_vaccinations_screen.dart';
import 'package:campaniia_vacunacion/presentation/screens/auth/update_password_screen.dart';


// Importas tus nuevos archivos de configuración
import 'config/supabase_config.dart';
import 'config/theme.dart';

// Importas tu pantalla de login (ajusta la ruta según la tengas)
import 'presentation/screens/auth/login_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Hive para el modo Offline
  await Hive.initFlutter();
  await Hive.openBox('vacunaciones_offline');

  // Inicializar Supabase usando las variables de tu archivo config
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campaña Vacunación',
      debugShowCheckedModeBanner: false, // Quita la etiqueta roja de "DEBUG"
      theme: AppTheme.theme, // Aplicas tu tema personalizado aquí
      home: LoginScreen(), 

      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => BrigadaDashboardScreen(),
        '/create-vaccination': (context) => RegisterVaccineScreen(),
        '/vaccinations': (context) => MyRecordsScreen(),
        '/campaign-reports': (context) => CampaignReportsScreen(),
        '/create-brigade-coordinator': (context) => CreateBrigadeCoordinatorScreen(),
        '/create-vaccinator': (context) => CreateVaccinatorScreen(),
        '/sector-vaccinations': (context) => const SectorVaccinationsScreen(),
        '/edit-my-vaccinations': (context) => const VacunadorSectorVaccinationsScreen(),
        '/update-password': (context) => const UpdatePasswordScreen(),
      }
    );
  }
}