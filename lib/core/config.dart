import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'supabase_storage.dart';

/// App configuration. Loads from SupabaseStorage first, then dart-define, then .env.
class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  static Future<AppConfig> load() async {
    // Prefer user-stored credentials (from onboarding)
    final storage = SupabaseStorage();
    var url = await storage.getUrl();
    var key = await storage.getAnonKey();
    if ((url ?? '').trim().isNotEmpty && (key ?? '').trim().isNotEmpty) {
      return AppConfig(supabaseUrl: url!.trim(), supabaseAnonKey: key!.trim());
    }
    // Fallback: dart-define (e.g. CI/production) then .env (local dev)
    url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    key = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (url.isEmpty || key.isEmpty) {
      url = url.isEmpty ? (dotenv.env['SUPABASE_URL'] ?? '') : url;
      key = key.isEmpty ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '') : key;
    }
    if (url.isNotEmpty && key.isNotEmpty) {
      return AppConfig(supabaseUrl: url, supabaseAnonKey: key);
    }
    return AppConfig(
      supabaseUrl: 'https://your-project.supabase.co',
      supabaseAnonKey: 'your-anon-key',
    );
  }
}
