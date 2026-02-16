import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/household_immich_service.dart';
import '../../core/immich_storage.dart';
import '../../data/household_repository.dart';

/// When user is authenticated and lands on home, syncs household Immich config
/// from Supabase into local storage if local storage is empty.
/// Re-checks on auth state changes to catch config created by webhook after login.
class SyncHouseholdImmichOnLogin extends StatefulWidget {
  const SyncHouseholdImmichOnLogin({super.key, required this.child});

  final Widget child;

  @override
  State<SyncHouseholdImmichOnLogin> createState() =>
      _SyncHouseholdImmichOnLoginState();
}

class _SyncHouseholdImmichOnLoginState extends State<SyncHouseholdImmichOnLogin> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfNeeded());
    // Listen to auth state changes to re-check when user logs in
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && data.session?.user != null) {
        _syncIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncIfNeeded() async {
    if (_isSyncing) return; // Prevent concurrent syncs
    _isSyncing = true;
    try {
      final storage = ImmichStorage();
      final url = await storage.getServerUrl();
      final key = await storage.getApiKey();
      // Only sync if local storage is empty (user hasn't configured their own Immich)
      if ((url ?? '').trim().isNotEmpty && (key ?? '').trim().isNotEmpty) {
        return;
      }
      final householdRepo = HouseholdRepository();
      final householdId = await householdRepo.getMyFirstHouseholdId();
      if (householdId == null) return;
      final hasConfig =
          await householdRepo.householdHasImmichConfig(householdId);
      if (!hasConfig) return;
      final householdImmich = HouseholdImmichService();
      final config =
          await householdImmich.getHouseholdImmichConfig(householdId);
      if (config.isConfigured && config.serverUrl != null && config.serverUrl!.trim().isNotEmpty && config.apiKey != null && config.apiKey!.trim().isNotEmpty) {
        final serverUrl = ImmichStorage.normalizeServerUrl(config.serverUrl) ?? config.serverUrl;
        if (serverUrl != null && serverUrl.isNotEmpty) {
          await storage.setServerUrl(serverUrl);
          await storage.setApiKey(config.apiKey);
          if (kDebugMode) {
            debugPrint('[SyncHouseholdImmich] Successfully synced Immich config from household');
          }
        }
      }
    } catch (e) {
      // Silent fail — user can configure Immich manually in settings
      // Log error for debugging but don't show to user
      debugPrint('[SyncHouseholdImmich] Failed to sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
