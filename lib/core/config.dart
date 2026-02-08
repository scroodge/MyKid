import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App configuration. Loads from dart-define first, then from .env.
class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  static Future<AppConfig> load() async {
    // Prefer dart-define (e.g. CI/production)
    var url = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    var key = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    // Use .env when not set via dart-define (local dev)
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
