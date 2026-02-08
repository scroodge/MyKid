import 'package:flutter/material.dart';

import '../../core/immich_client.dart';
import '../../core/immich_storage.dart';

class ImmichSettingsScreen extends StatefulWidget {
  const ImmichSettingsScreen({super.key});

  @override
  State<ImmichSettingsScreen> createState() => _ImmichSettingsScreenState();
}

class _ImmichSettingsScreenState extends State<ImmichSettingsScreen> {
  final _storage = ImmichStorage();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = await _storage.getServerUrl();
    final key = await _storage.getApiKey();
    if (mounted) {
      _urlController.text = url ?? '';
      _apiKeyController.text = key ?? '';
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    final key = _apiKeyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() => _message = 'Enter URL and API key');
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
      setState(() {
        _loading = false;
        _message = ok ? 'Connected successfully' : 'Connection failed';
      });
      if (ok) {
        await _save(showSnackBar: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connected and saved')),
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
          .showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Immich'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your Immich server URL and API key (create key in Immich Settings → API Keys). A successful Test connection saves them.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://photos.example.com',
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key',
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
            label: Text(_loading ? 'Testing...' : 'Test connection'),
          ),
        ],
      ),
    );
  }
}
