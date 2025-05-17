import 'package:final_project/modules/admin/controllers/dashboard_controller.dart';
import 'package:final_project/modules/admin/repositories/admin_repository.dart';
import 'package:final_project/modules/manager/controllers/manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/services/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionHelper.initialize();
  await Supabase.initialize(
    url: 'https://iygrsggrzjboheeyumtm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5Z3JzZ2dyempib2hlZXl1bXRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY5ODQ4MTEsImV4cCI6MjA2MjU2MDgxMX0.3xI16ki55d8AdFRiG-xkvrr8GtZY83FxLsSgQnDNaac', // Replace with your Supabase anon key
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AdminRepository>(create: (_) => AdminRepository()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => ManagerDashboardProvider()),
        // Add other providers if needed
      ],
      child: const MyApp(),
    ),
  );
}
