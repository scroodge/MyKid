import 'supabase_storage.dart';

/// App configuration. Loads from SupabaseStorage first, then dart-define, then default.
/// Managed users (Premium) on new device: use default → Login with email+password only.
/// Self-hosters: use onboarding or "Change Supabase" to enter their own backend.
class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Default managed backend. Used when no storage and no dart-define.
  /// For self-hosted: use onboarding or Settings → Change Supabase.
  static const String defaultSupabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String defaultSupabaseAnonKey =
      'YOUR_ANON_KEY';

  static Future<AppConfig> load() async {
    // 1. User-stored (from onboarding or "Change Supabase" → custom backend)
    final storage = SupabaseStorage();
    var url = await storage.getUrl();
    var key = await storage.getAnonKey();
    if ((url ?? '').trim().isNotEmpty && (key ?? '').trim().isNotEmpty) {
      return AppConfig(supabaseUrl: url!.trim(), supabaseAnonKey: key!.trim());
    }
    // 2. Dart-define (build-time, e.g. CI/production)
    url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    key = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (url.isNotEmpty && key.isNotEmpty) {
      return AppConfig(supabaseUrl: url, supabaseAnonKey: key);
    }
    // 3. User chose "Change Supabase" → show onboarding to enter custom backend
    if (await storage.wasClearedForCustom()) {
      return AppConfig(
        supabaseUrl: 'https://your-project.supabase.co',
        supabaseAnonKey: 'your-anon-key',
      );
    }
    // 4. Default managed backend — Premium users on new device: just email+password
    return AppConfig(
      supabaseUrl: defaultSupabaseUrl,
      supabaseAnonKey: defaultSupabaseAnonKey,
    );
  }
}
