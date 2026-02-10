import 'package:flutter/material.dart';

import '../../core/household_immich_service.dart';
import '../../core/immich_storage.dart';
import '../../data/household_repository.dart';

/// When user is authenticated and lands on home, syncs household Immich config
/// from Supabase into local storage if local storage is empty.
class SyncHouseholdImmichOnLogin extends StatefulWidget {
  const SyncHouseholdImmichOnLogin({super.key, required this.child});

  final Widget child;

  @override
  State<SyncHouseholdImmichOnLogin> createState() =>
      _SyncHouseholdImmichOnLoginState();
}

class _SyncHouseholdImmichOnLoginState extends State<SyncHouseholdImmichOnLogin> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfNeeded());
  }

  Future<void> _syncIfNeeded() async {
    try {
      final storage = ImmichStorage();
      final url = await storage.getServerUrl();
      final key = await storage.getApiKey();
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
      if (config.isConfigured) {
        await storage.setServerUrl(config.serverUrl);
        await storage.setApiKey(config.apiKey);
      }
    } catch (_) {
      // Silent fail — user can configure Immich manually in settings
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
