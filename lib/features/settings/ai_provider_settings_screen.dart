import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai_provider_storage.dart';
import '../../core/ai_vision_service.dart';
import '../../l10n/app_localizations.dart';

class AiProviderSettingsScreen extends StatefulWidget {
  const AiProviderSettingsScreen({super.key});

  @override
  State<AiProviderSettingsScreen> createState() => _AiProviderSettingsScreenState();
}

class _AiProviderSettingsScreenState extends State<AiProviderSettingsScreen> {
  final _storage = AiProviderStorage();
  final _service = AiVisionService();
  final _openAiController = TextEditingController();
  final _geminiController = TextEditingController();
  final _claudeController = TextEditingController();
  final _deepSeekController = TextEditingController();
  final _customAiController = TextEditingController();
  final _customAiBaseUrlController = TextEditingController();
  String? _selectedProvider;
  bool _loading = false;
  String? _message;
  bool _obscureOpenAi = true;
  bool _obscureGemini = true;
  bool _obscureClaude = true;
  bool _obscureDeepSeek = true;
  bool _obscureCustomAi = true;

  @override
  void initState() {
    super.initState();
    _load();
    _openAiController.addListener(_onFieldsChanged);
    _geminiController.addListener(_onFieldsChanged);
    _claudeController.addListener(_onFieldsChanged);
    _deepSeekController.addListener(_onFieldsChanged);
    _customAiController.addListener(_onFieldsChanged);
    _customAiBaseUrlController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() => setState(() {});

  Future<void> _load() async {
    final openAiKey = await _storage.getOpenAiKey();
    final geminiKey = await _storage.getGeminiKey();
    final claudeKey = await _storage.getClaudeKey();
    final deepSeekKey = await _storage.getDeepSeekKey();
    final customAiKey = await _storage.getCustomAiKey();
    final customAiBaseUrl = await _storage.getCustomAiBaseUrl();
    final selected = await _storage.getSelectedProvider();
    if (mounted) {
      _openAiController.text = openAiKey ?? '';
      _geminiController.text = geminiKey ?? '';
      _claudeController.text = claudeKey ?? '';
      _deepSeekController.text = deepSeekKey ?? '';
      _customAiController.text = customAiKey ?? '';
      _customAiBaseUrlController.text = customAiBaseUrl ?? '';
      _selectedProvider = selected ?? 'gemini'; // Default to Gemini (has free tier)
      setState(() {});
    }
  }

  Future<void> _testConnection(String provider) async {
    String? apiKey;
    switch (provider) {
      case 'openai':
        apiKey = _openAiController.text.trim();
        break;
      case 'gemini':
        apiKey = _geminiController.text.trim();
        break;
      case 'claude':
        apiKey = _claudeController.text.trim();
        break;
      case 'deepseek':
        apiKey = _deepSeekController.text.trim();
        break;
      case 'customai':
        apiKey = _customAiController.text.trim();
        break;
    }

    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _message = AppLocalizations.of(context)!.enterApiKey);
      return;
    }

    // Save key temporarily for test
    switch (provider) {
      case 'openai':
        await _storage.setOpenAiKey(apiKey);
        break;
      case 'gemini':
        await _storage.setGeminiKey(apiKey);
        break;
      case 'claude':
        await _storage.setClaudeKey(apiKey);
        break;
      case 'deepseek':
        await _storage.setDeepSeekKey(apiKey);
        break;
      case 'customai':
        await _storage.setCustomAiKey(apiKey);
        await _storage.setCustomAiBaseUrl(_customAiBaseUrlController.text.trim());
        break;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await _service.testConnection(provider);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _message = result.success ? l10n.connectedSuccessfully : result.error ?? l10n.connectionFailed;
      });
      if (result.success) {
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
    await _storage.setOpenAiKey(
        _openAiController.text.trim().isEmpty ? null : _openAiController.text.trim());
    await _storage.setGeminiKey(
        _geminiController.text.trim().isEmpty ? null : _geminiController.text.trim());
    await _storage.setClaudeKey(
        _claudeController.text.trim().isEmpty ? null : _claudeController.text.trim());
    await _storage.setDeepSeekKey(
        _deepSeekController.text.trim().isEmpty ? null : _deepSeekController.text.trim());
    await _storage.setCustomAiKey(
        _customAiController.text.trim().isEmpty ? null : _customAiController.text.trim());
    await _storage.setCustomAiBaseUrl(
        _customAiBaseUrlController.text.trim().isEmpty ? null : _customAiBaseUrlController.text.trim());
    await _storage.setSelectedProvider(_selectedProvider);
    if (mounted && showSnackBar) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saved)));
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _openAiController.removeListener(_onFieldsChanged);
    _geminiController.removeListener(_onFieldsChanged);
    _claudeController.removeListener(_onFieldsChanged);
    _deepSeekController.removeListener(_onFieldsChanged);
    _customAiController.removeListener(_onFieldsChanged);
    _customAiBaseUrlController.removeListener(_onFieldsChanged);
    _openAiController.dispose();
    _geminiController.dispose();
    _claudeController.dispose();
    _deepSeekController.dispose();
    _customAiController.dispose();
    _customAiBaseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiProviderSettings),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.aiProviderSettingsDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.selectProvider,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          RadioListTile<String>(
            title: Text(l10n.openAi),
            subtitle: Text(l10n.openAiDescription),
            value: 'openai',
            groupValue: _selectedProvider,
            onChanged: (value) => setState(() => _selectedProvider = value),
          ),
          RadioListTile<String>(
            title: Text(l10n.gemini),
            subtitle: Text(l10n.geminiDescription),
            value: 'gemini',
            groupValue: _selectedProvider,
            onChanged: (value) => setState(() => _selectedProvider = value),
          ),
          RadioListTile<String>(
            title: Text(l10n.claude),
            subtitle: Text(l10n.claudeDescription),
            value: 'claude',
            groupValue: _selectedProvider,
            onChanged: (value) => setState(() => _selectedProvider = value),
          ),
          RadioListTile<String>(
            title: Text(l10n.deepSeek),
            subtitle: Text(l10n.deepSeekDescription),
            value: 'deepseek',
            groupValue: _selectedProvider,
            onChanged: (value) => setState(() => _selectedProvider = value),
          ),
          RadioListTile<String>(
            title: Text(l10n.customAi),
            subtitle: Text(l10n.customAiDescription),
            value: 'customai',
            groupValue: _selectedProvider,
            onChanged: (value) => setState(() => _selectedProvider = value),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.apiKeys,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.openAi,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _openAiController,
                    decoration: InputDecoration(
                      labelText: l10n.apiKey,
                      hintText: l10n.enterApiKey,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureOpenAi ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureOpenAi = !_obscureOpenAi),
                      ),
                    ),
                    obscureText: _obscureOpenAi,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _openUrl('https://platform.openai.com/api-keys'),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.getApiKey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.gemini,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _geminiController,
                    decoration: InputDecoration(
                      labelText: l10n.apiKey,
                      hintText: l10n.enterApiKey,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureGemini ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureGemini = !_obscureGemini),
                      ),
                    ),
                    obscureText: _obscureGemini,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _openUrl('https://makersuite.google.com/app/apikey'),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.getApiKey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.claude,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _claudeController,
                    decoration: InputDecoration(
                      labelText: l10n.apiKey,
                      hintText: l10n.enterApiKey,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureClaude ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureClaude = !_obscureClaude),
                      ),
                    ),
                    obscureText: _obscureClaude,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _openUrl('https://console.anthropic.com/settings/keys'),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.getApiKey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.deepSeek,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _deepSeekController,
                    decoration: InputDecoration(
                      labelText: l10n.apiKey,
                      hintText: l10n.enterApiKey,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureDeepSeek ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureDeepSeek = !_obscureDeepSeek),
                      ),
                    ),
                    obscureText: _obscureDeepSeek,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _openUrl('https://platform.deepseek.com/api_keys'),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.getApiKey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.customAi,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customAiBaseUrlController,
                    decoration: InputDecoration(
                      labelText: l10n.customAiBaseUrl,
                      hintText: l10n.customAiBaseUrlHint,
                    ),
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customAiController,
                    decoration: InputDecoration(
                      labelText: l10n.apiKey,
                      hintText: l10n.enterApiKey,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCustomAi ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureCustomAi = !_obscureCustomAi),
                      ),
                    ),
                    obscureText: _obscureCustomAi,
                    autocorrect: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_message != null) ...[
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
          ],
          if (_selectedProvider != null)
            FilledButton.icon(
              onPressed: _loading ? null : () => _testConnection(_selectedProvider!),
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(_loading ? l10n.testing : l10n.testConnection),
            ),
        ],
      ),
    );
  }
}
