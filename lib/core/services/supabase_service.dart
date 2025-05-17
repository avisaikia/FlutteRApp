import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://iygrsggrzjboheeyumtm.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5Z3JzZ2dyempib2hlZXl1bXRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY5ODQ4MTEsImV4cCI6MjA2MjU2MDgxMX0.3xI16ki55d8AdFRiG-xkvrr8GtZY83FxLsSgQnDNaac';

  static final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
