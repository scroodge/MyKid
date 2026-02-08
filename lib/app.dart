import 'package:flutter/material.dart';

import 'core/brand/mykid_brand.dart';
import 'features/auth/auth_guard.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/children/children_list_screen.dart';
import 'features/home/home_screen.dart';
import 'features/import/batch_import_screen.dart';
import 'features/settings/settings_screen.dart';

class MyKidApp extends StatelessWidget {
  const MyKidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyKid Journal',
      theme: MyKidTheme.lightTheme,
      darkTheme: MyKidTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGuard(child: HomeScreen()),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/children': (context) => const ChildrenListScreen(),
        '/import': (context) => const BatchImportScreen(),
      },
    );
  }
}
