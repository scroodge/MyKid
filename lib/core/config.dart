import 'supabase_storage.dart';

/// App configuration. Loads from SupabaseStorage first, then dart-define.
/// No .env — use onboarding or --dart-define for production builds.
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
    // Fallback: dart-define (e.g. CI/production)
    url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    key = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (url.isNotEmpty && key.isNotEmpty) {
      return AppConfig(supabaseUrl: url, supabaseAnonKey: key);
    }
    return AppConfig(
      supabaseUrl: 'https://your-project.supabase.co',
      supabaseAnonKey: 'your-anon-key',
    );
  }
}
