import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'data/local/journal_cache.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing (e.g. copy from .env.example first)
  }
  await JournalCache.init();
  final config = await AppConfig.load();
  // Only initialize Supabase if we have valid credentials (user-stored or .env)
  final hasValidConfig =
      config.supabaseUrl.isNotEmpty &&
      config.supabaseAnonKey.isNotEmpty &&
      !config.supabaseUrl.contains('your-project') &&
      config.supabaseAnonKey != 'your-anon-key';
  if (hasValidConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  }
  runApp(MyKidApp(supabaseInitialized: hasValidConfig));
}
