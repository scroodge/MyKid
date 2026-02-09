import 'package:flutter/material.dart';

import 'core/brand/mykid_brand.dart';
import 'features/auth/auth_guard.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/children/children_list_screen.dart';
import 'features/home/home_screen.dart';
import 'features/import/batch_import_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/immich_settings_screen.dart';
import 'features/settings/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'l10n/app_localizations.dart';

class MyKidApp extends StatelessWidget {
  const MyKidApp({super.key, required this.supabaseInitialized});

  final bool supabaseInitialized;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyKid Journal',
      theme: MyKidTheme.lightTheme,
      darkTheme: MyKidTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: supabaseInitialized ? '/' : '/onboarding',
      routes: {
        '/': (context) => const AuthGuard(child: HomeScreen()),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings-immich': (context) => const ImmichSettingsScreen(),
        '/children': (context) => const ChildrenListScreen(),
        '/import': (context) => const BatchImportScreen(),
      },
    );
  }
}
