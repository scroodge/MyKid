import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import 'features/settings/my_family_screen.dart';
import 'features/settings/ai_provider_settings_screen.dart';
import 'features/settings/ai_gateway_tokens_screen.dart';
import 'features/settings/immich_settings_screen.dart';
import 'features/settings/profile_screen.dart';
import 'features/settings/licenses_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/subscription_screen.dart';
import 'features/settings/subscription_success_screen.dart';
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
        debugPrint('Deep link (initial): $uri');
        _handleDeepLink(uri);
      }
    }).catchError((error) {
      debugPrint('Error getting initial deep link: $error');
    });

    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link (stream): $uri');
      _handleDeepLink(uri);
    }, onError: (error) {
      debugPrint('Error listening to deep links: $error');
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Handling deep link: $uri');
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
      // Handle mykid://subscription-success (return from Stripe Checkout)
      else if (uri.host == 'subscription-success' || (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'subscription-success')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_navigatorKey.currentContext != null) {
            Navigator.of(_navigatorKey.currentContext!).pushNamed('/subscription-success');
          }
        });
      }
      // Handle mykid://auth/confirm?token=<invite_token>
      // This is for email confirmation redirect from Supabase
      else if (uri.host == 'auth' && uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'confirm') {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_navigatorKey.currentContext == null) return;
          
          // Check if there's an invite token (for family invites)
          final inviteToken = uri.queryParameters['invite_token'];
          if (inviteToken != null) {
            Navigator.of(_navigatorKey.currentContext!).pushNamed(
              '/accept-invite',
              arguments: inviteToken,
            );
            return;
          }
          
          // This is email confirmation from Supabase
          // Supabase redirects here after processing the token on the server
          // The token might be in the URL, but usually it's already processed
          try {
            // Check if Supabase is initialized
            if (!widget.supabaseInitialized) {
              // Supabase not initialized - redirect to onboarding
              Navigator.of(_navigatorKey.currentContext!).pushNamedAndRemoveUntil('/onboarding', (_) => false);
              return;
            }
            
            // Check if there's a token in the URL (sometimes Supabase passes it)
            final token = uri.queryParameters['token'];
            final type = uri.queryParameters['type'];
            
            // Check session - Supabase processes the token server-side
            // The session should be available after the redirect
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              // Email confirmed, user is logged in - go to home
              Navigator.of(_navigatorKey.currentContext!).pushNamedAndRemoveUntil('/', (_) => false);
            } else {
              // Session not available - might need to wait a bit
              // Try checking again after a short delay
              await Future.delayed(const Duration(milliseconds: 500));
              final newSession = Supabase.instance.client.auth.currentSession;
              if (newSession != null) {
                Navigator.of(_navigatorKey.currentContext!).pushNamedAndRemoveUntil('/', (_) => false);
              } else {
                // No session - redirect to login with message
                ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                  const SnackBar(
                    content: Text('Email confirmed. Please sign in.'),
                  ),
                );
                Navigator.of(_navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            }
          } catch (e) {
            // Error checking session - redirect to login
            Navigator.of(_navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (_) => false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: WidgetsBinding.instance.platformDispatcher.locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: Builder(
        builder: (context) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: AppLocalizations.of(context)!.appTitle,
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
            '/settings-ai-providers': (context) => const AiProviderSettingsScreen(),
            '/settings-ai-gateway-token': (context) => const AiGatewayTokensScreen(),
            '/subscription': (context) => const SubscriptionScreen(),
            '/subscription-success': (context) => const SubscriptionSuccessScreen(),
            '/household-invites': (context) => const HouseholdInvitesScreen(),
            '/my-family': (context) => const MyFamilyScreen(),
            '/accept-invite': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final token = args is String ? args : null;
              return AcceptInviteScreen(token: token);
            },
            '/children': (context) => const ChildrenListScreen(),
            '/import': (context) => const BatchImportScreen(),
            '/licenses': (context) => const LicensesScreen(),
          },
        ),
      ),
    );
  }
}
