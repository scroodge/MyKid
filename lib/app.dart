import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/brand/mykid_brand.dart';
import 'features/auth/auth_guard.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/children/children_list_screen.dart';
import 'features/home/home_screen.dart';
import 'features/import/batch_import_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/accept_invite_screen.dart';
import 'features/settings/household_invites_screen.dart';
import 'features/settings/immich_settings_screen.dart';
import 'features/settings/profile_screen.dart';
import 'features/settings/licenses_screen.dart';
import 'features/settings/settings_screen.dart';
import 'l10n/app_localizations.dart';

class MyKidApp extends StatefulWidget {
  const MyKidApp({super.key, required this.supabaseInitialized});

  final bool supabaseInitialized;

  @override
  State<MyKidApp> createState() => _MyKidAppState();
}

class _MyKidAppState extends State<MyKidApp> {
  final _appLinks = AppLinks();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // Handle initial link (if app was opened via deep link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'mykid') {
      // Handle mykid://invite/<token>
      if (uri.host == 'invite' || (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'invite')) {
        String? token;
        
        if (uri.host == 'invite') {
          if (uri.pathSegments.isNotEmpty) {
            token = uri.pathSegments.first;
          } else if (uri.path.isNotEmpty) {
            token = uri.path.replaceFirst('/', '');
          }
        } else if (uri.pathSegments.length > 1) {
          token = uri.pathSegments[1];
        }
        
        if (token != null && token.isNotEmpty) {
          // Navigate to accept-invite screen with token
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_navigatorKey.currentContext != null) {
              Navigator.of(_navigatorKey.currentContext!).pushNamed(
                '/accept-invite',
                arguments: token,
              );
            }
          });
        }
      }
      // Handle mykid://auth/confirm?token=<invite_token>
      // This is for email confirmation redirect
      else if (uri.host == 'auth' && uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'confirm') {
        final inviteToken = uri.queryParameters['invite_token'];
        if (inviteToken != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_navigatorKey.currentContext != null) {
              Navigator.of(_navigatorKey.currentContext!).pushNamed(
                '/accept-invite',
                arguments: inviteToken,
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'MyKid Journal',
      theme: MyKidTheme.lightTheme,
      darkTheme: MyKidTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.supabaseInitialized ? '/' : '/onboarding',
      routes: {
        '/': (context) => const AuthGuard(child: HomeScreen()),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings-immich': (context) => const ImmichSettingsScreen(),
        '/household-invites': (context) => const HouseholdInvitesScreen(),
        '/accept-invite': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final token = args is String ? args : null;
          return AcceptInviteScreen(token: token);
        },
        '/children': (context) => const ChildrenListScreen(),
        '/import': (context) => const BatchImportScreen(),
        '/licenses': (context) => const LicensesScreen(),
      },
    );
  }
}
