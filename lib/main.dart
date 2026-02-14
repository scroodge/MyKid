import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'data/local/face_embeddings_cache.dart';
import 'data/local/journal_cache.dart';
import 'data/local/scanned_photos_cache.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JournalCache.init();
  await FaceEmbeddingsCache.init();
  await ScannedPhotosCache.init();
  final config = await AppConfig.load();
  // Only initialize Supabase if we have valid credentials (user-stored or .env)
  final hasValidConfig =
      config.supabaseUrl.isNotEmpty &&
      config.supabasePublishableKey.isNotEmpty &&
      !config.supabaseUrl.contains('your-project') &&
      config.supabasePublishableKey != 'your-publishable-key';
  if (hasValidConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabasePublishableKey,
    );
  }
  runApp(MyKidApp(supabaseInitialized: hasValidConfig));
}
