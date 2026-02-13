import 'package:flutter/material.dart';

import '../../core/ai_gateway_service.dart';
import '../../l10n/app_localizations.dart';

/// Screen for viewing AI Gateway usage stats.
/// Tokens are created automatically when Premium subscription is activated.
class AiGatewayTokensScreen extends StatefulWidget {
  const AiGatewayTokensScreen({super.key});

  @override
  State<AiGatewayTokensScreen> createState() => _AiGatewayTokensScreenState();
}

class _AiGatewayTokensScreenState extends State<AiGatewayTokensScreen> {
  final _gatewayService = AiGatewayService();
  bool _usageLoading = false;
  int? _inputTokens;
  int? _outputTokens;
  int? _totalTokens;
  String? _usageError;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    setState(() {
      _usageLoading = true;
      _usageError = null;
    });
    final result = await _gatewayService.getUsage();
    if (mounted) {
      setState(() {
        _usageLoading = false;
        _inputTokens = result.inputTokens ?? 0;
        _outputTokens = result.outputTokens ?? 0;
        _totalTokens = result.totalTokens ?? 0;
        _usageError = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiGatewayToken),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.aiGatewayTokenSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          // Usage
          Text(
            l10n.aiGatewayUsage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aiGatewayUsageSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          if (_usageLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_usageError != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _usageError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.aiGatewayUsageStats(
                    '$_inputTokens',
                    '$_outputTokens',
                    '$_totalTokens',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
