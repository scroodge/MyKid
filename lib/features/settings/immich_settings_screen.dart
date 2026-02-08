import 'package:flutter/material.dart';

import '../../core/household_immich_service.dart';
import '../../core/immich_client.dart';
import '../../core/immich_storage.dart';
import '../../data/household_repository.dart';
import '../../l10n/app_localizations.dart';

class ImmichSettingsScreen extends StatefulWidget {
  const ImmichSettingsScreen({super.key});

  @override
  State<ImmichSettingsScreen> createState() => _ImmichSettingsScreenState();
}

class _ImmichSettingsScreenState extends State<ImmichSettingsScreen> {
  final _storage = ImmichStorage();
  final _householdRepo = HouseholdRepository();
  final _householdImmich = HouseholdImmichService();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _obscureKey = true;
  String? _householdId;
  bool _familyHasImmich = false;
  bool _loadingFamily = false;

  @override
  void initState() {
    super.initState();
    _load();
    _urlController.addListener(_onFieldsChanged);
    _apiKeyController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() => setState(() {});

  Future<void> _load() async {
    final url = await _storage.getServerUrl();
    final key = await _storage.getApiKey();
    if (mounted) {
      _urlController.text = url ?? '';
      _apiKeyController.text = key ?? '';
    }
    final hasLocal = (url ?? '').trim().isNotEmpty && (key ?? '').trim().isNotEmpty;
    if (!hasLocal && mounted) {
      _loadFamilyImmichOffer();
    }
  }

  Future<void> _loadFamilyImmichOffer() async {
    setState(() => _loadingFamily = true);
    try {
      final householdId = await _householdRepo.getMyFirstHouseholdId();
      if (householdId == null || !mounted) return;
      final hasConfig = await _householdRepo.householdHasImmichConfig(householdId);
      if (mounted) {
        setState(() {
          _householdId = householdId;
          _familyHasImmich = hasConfig;
          _loadingFamily = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFamily = false);
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    final key = _apiKeyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() => _message = AppLocalizations.of(context)!.enterUrlAndKey);
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    final baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final client = ImmichClient(baseUrl: baseUrl, apiKey: key);
    final ok = await client.checkConnection();
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _message = ok ? l10n.connectedSuccessfully : l10n.connectionFailed;
      });
      if (ok) {
        await _save(showSnackBar: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.connectedAndSaved)),
          );
        }
      }
    }
  }

  Future<void> _save({bool showSnackBar = true}) async {
    await _storage.setServerUrl(
        _urlController.text.trim().isEmpty ? null : _urlController.text.trim());
    await _storage.setApiKey(_apiKeyController.text.trim().isEmpty
        ? null
        : _apiKeyController.text.trim());
    if (mounted && showSnackBar) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saved)));
    }
  }

  Future<void> _useFamilyImmich() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.useFamilyImmich),
        content: Text(l10n.useFamilyImmichDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirmed != true || _householdId == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final config = await _householdImmich.getHouseholdImmichConfig(_householdId!);
      if (!config.isConfigured || !mounted) {
        setState(() {
          _loading = false;
          _message = l10n.useFamilyImmichFailed;
        });
        return;
      }
      await _storage.setServerUrl(config.serverUrl);
      await _storage.setApiKey(config.apiKey);
      if (mounted) {
        _urlController.text = config.serverUrl ?? '';
        _apiKeyController.text = config.apiKey ?? '';
        setState(() {
          _loading = false;
          _familyHasImmich = false;
          _message = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saved)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = AppLocalizations.of(context)!.useFamilyImmichFailed;
        });
      }
    }
  }

  Future<void> _saveToFamily() async {
    final l10n = AppLocalizations.of(context)!;
    final url = _urlController.text.trim();
    final key = _apiKeyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() => _message = l10n.enterUrlAndKey);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveToFamily),
        content: Text(l10n.saveToFamilyDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      final householdId = await _householdRepo.getOrCreateMyHousehold();
      if (householdId == null || !mounted) return;
      await _householdImmich.setHouseholdImmichConfig(householdId, serverUrl: url, apiKey: key);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saved)));
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onFieldsChanged);
    _apiKeyController.removeListener(_onFieldsChanged);
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.immich),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppLocalizations.of(context)!.immichDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (_loadingFamily) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ] else if (_familyHasImmich &&
              (_urlController.text.trim().isEmpty || _apiKeyController.text.trim().isEmpty)) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.useFamilyImmich,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _useFamilyImmich,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.family_restroom, size: 20),
                      label: Text(AppLocalizations.of(context)!.useFamilyImmich),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.serverUrl,
              hintText: AppLocalizations.of(context)!.serverUrlHint,
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.apiKey,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            obscureText: _obscureKey,
            autocorrect: false,
          ),
          const SizedBox(height: 24),
          if (_message != null) ...[
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: _loading ? null : _testConnection,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering),
            label: Text(_loading ? AppLocalizations.of(context)!.testing : AppLocalizations.of(context)!.testConnection),
          ),
          if (_urlController.text.trim().isNotEmpty && _apiKeyController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _saveToFamily,
              icon: const Icon(Icons.family_restroom, size: 20),
              label: Text(AppLocalizations.of(context)!.saveToFamily),
            ),
          ],
        ],
      ),
    );
  }
}
