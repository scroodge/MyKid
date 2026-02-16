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
      if (kDebugMode) {
        debugPrint('[SyncHouseholdImmich] Checking sync: localUrl=${url?.isNotEmpty ?? false}, localKey=${key?.isNotEmpty ?? false}');
      }
      // Only sync if local storage is empty (user hasn't configured their own Immich)
      if ((url ?? '').trim().isNotEmpty && (key ?? '').trim().isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[SyncHouseholdImmich] Skipping sync: local storage already has config');
        }
        return;
      }
      final householdRepo = HouseholdRepository();
      final householdId = await householdRepo.getMyFirstHouseholdId();
      if (householdId == null) {
        if (kDebugMode) {
          debugPrint('[SyncHouseholdImmich] Skipping sync: no household found');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[SyncHouseholdImmich] Found household: $householdId');
      }
      final hasConfig =
          await householdRepo.householdHasImmichConfig(householdId);
      if (!hasConfig) {
        if (kDebugMode) {
          debugPrint('[SyncHouseholdImmich] Skipping sync: household has no Immich config');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[SyncHouseholdImmich] Household has Immich config, fetching...');
      }
      final householdImmich = HouseholdImmichService();
      final config =
          await householdImmich.getHouseholdImmichConfig(householdId);
      if (kDebugMode) {
        debugPrint('[SyncHouseholdImmich] Config fetched: serverUrl=${config.serverUrl?.isNotEmpty ?? false}, apiKey=${config.apiKey?.isNotEmpty ?? false}');
      }
      if (config.isConfigured && config.serverUrl != null && config.serverUrl!.trim().isNotEmpty && config.apiKey != null && config.apiKey!.trim().isNotEmpty) {
        final serverUrl = ImmichStorage.normalizeServerUrl(config.serverUrl) ?? config.serverUrl;
        if (serverUrl != null && serverUrl.isNotEmpty) {
          await storage.setServerUrl(serverUrl);
          await storage.setApiKey(config.apiKey);
          if (kDebugMode) {
            debugPrint('[SyncHouseholdImmich] Successfully synced Immich config from household: $serverUrl');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('[SyncHouseholdImmich] Config not fully configured: serverUrl=${config.serverUrl}, apiKey=${config.apiKey?.isNotEmpty ?? false}');
        }
      }
    } catch (e, stackTrace) {
      // Silent fail — user can configure Immich manually in settings
      // Log error for debugging but don't show to user
      debugPrint('[SyncHouseholdImmich] Failed to sync: $e');
      if (kDebugMode) {
        debugPrint('[SyncHouseholdImmich] Stack trace: $stackTrace');
      }
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
