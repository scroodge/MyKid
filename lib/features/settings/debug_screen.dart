import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ai_provider_storage.dart';
import '../../core/config.dart';
import '../../core/immich_storage.dart';
import '../../l10n/app_localizations.dart';
import 'settings_screen.dart';

String _maskKey(String? value) {
  if (value == null || value.isEmpty) return '—';
  final t = value.trim();
  if (t.length <= 4) return '••••';
  return '••••${t.substring(t.length - 4)}';
}

String _providerDisplayName(String? id) {
  if (id == null || id.isEmpty) return '—';
  switch (id) {
    case 'openai': return 'OpenAI';
    case 'gemini': return 'Gemini';
    case 'claude': return 'Claude';
    case 'deepseek': return 'DeepSeek';
    case 'customai': return 'Custom AI';
    default: return id;
  }
}

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _immichStorage = ImmichStorage();
  final _aiStorage = AiProviderStorage();
  String? _supabaseUrl;
  String? _immichUrlRaw;
  String? _immichUrlNormalized;
  String? _immichKeyMasked;
  String? _aiProvider;
  String? _customAiBaseUrl;
  String? _aiKeysSummary;
  bool _managedAiUsed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await AppConfig.load();
      _supabaseUrl = config.supabaseUrl;

      _immichUrlRaw = await _immichStorage.getServerUrlRaw();
      _immichUrlNormalized = await _immichStorage.getServerUrl();
      final immichKey = await _immichStorage.getApiKey();
      _immichKeyMasked = _maskKey(immichKey);

      final selectedProvider = await _aiStorage.getSelectedProvider();
      _aiProvider = _providerDisplayName(selectedProvider);
      _customAiBaseUrl = await _aiStorage.getCustomAiBaseUrl();
      final openai = await _aiStorage.getOpenAiKey();
      final gemini = await _aiStorage.getGeminiKey();
      final claude = await _aiStorage.getClaudeKey();
      final deepseek = await _aiStorage.getDeepSeekKey();
      final customKey = await _aiStorage.getCustomAiKey();
      _aiKeysSummary = 'OpenAI: ${_maskKey(openai)} | Gemini: ${_maskKey(gemini)} | Claude: ${_maskKey(claude)} | DeepSeek: ${_maskKey(deepseek)} | Custom: ${_maskKey(customKey)}';
      // Managed AI (ai-proxy) is used when there is no local provider or no key for selected provider
      bool hasLocalKey = false;
      if (selectedProvider != null) {
        switch (selectedProvider) {
          case 'openai': hasLocalKey = (openai ?? '').trim().isNotEmpty; break;
          case 'gemini': hasLocalKey = (gemini ?? '').trim().isNotEmpty; break;
          case 'claude': hasLocalKey = (claude ?? '').trim().isNotEmpty; break;
          case 'deepseek': hasLocalKey = (deepseek ?? '').trim().isNotEmpty; break;
          case 'customai': hasLocalKey = (customKey ?? '').trim().isNotEmpty && (_customAiBaseUrl ?? '').trim().isNotEmpty; break;
          default: break;
        }
      }
      _managedAiUsed = !hasLocalKey;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String get _textSummary {
    final buf = StringBuffer();
    buf.writeln('=== Debug info ===');
    buf.writeln('Supabase URL: $_supabaseUrl');
    buf.writeln('Immich URL (stored raw): $_immichUrlRaw');
    buf.writeln('Immich URL (normalized): $_immichUrlNormalized');
    buf.writeln('Immich API key: $_immichKeyMasked');
    buf.writeln('Managed AI (gateway): ${_managedAiUsed ? 'Yes' : 'No (local keys)'}');
    if (_managedAiUsed) buf.writeln('  → Requests use gateway; provider below is only the one selected in Settings.');
    buf.writeln('AI provider (selected): $_aiProvider');
    buf.writeln('Custom AI base URL: $_customAiBaseUrl');
    buf.writeln('AI keys: $_aiKeysSummary');
    buf.writeln('App version: ${SettingsScreen.appVersion}');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debugInfo),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _loading
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _textSummary));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.debugInfoCopied)),
                    );
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section(l10n.debugInfoSupabase, [
                  _row('URL', _supabaseUrl ?? '—'),
                ]),
                const SizedBox(height: 24),
                _section(l10n.debugInfoImmich, [
                  _row('URL (stored)', _immichUrlRaw ?? '—', highlight: _immichUrlRaw != null && _immichUrlRaw != _immichUrlNormalized),
                  _row('URL (used)', _immichUrlNormalized ?? '—'),
                  _row('API key', _immichKeyMasked ?? '—'),
                ]),
                const SizedBox(height: 24),
                _section(l10n.debugInfoAi, [
                  _row(l10n.debugInfoManagedAi, _managedAiUsed ? l10n.debugInfoManagedAiUsed : l10n.debugInfoManagedAiNotUsed),
                  if (_managedAiUsed) _row('', l10n.debugInfoManagedAiHint),
                  _row(l10n.debugInfoProviderSelected, _aiProvider ?? '—'),
                  _row('Custom AI base URL', _customAiBaseUrl ?? '—'),
                  _row('Keys', _aiKeysSummary ?? '—'),
                ]),
                const SizedBox(height: 24),
                _section(l10n.debugInfoApp, [
                  _row('Version', SettingsScreen.appVersion),
                ]),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SelectableText.rich(
        TextSpan(
          children: [
            if (label.isNotEmpty) TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: highlight ? Theme.of(context).colorScheme.error : null)),
            TextSpan(text: value, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: highlight ? Theme.of(context).colorScheme.error : null)),
          ],
        ),
      ),
    );
  }
}
