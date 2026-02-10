import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'sync_household_immich_on_login.dart';

/// Redirects to login if not authenticated.
class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data!.session != null &&
            snapshot.data!.session?.user != null) {
          return SyncHouseholdImmichOnLogin(child: child);
        }
        return LoginScreen();
      },
    );
  }
}
