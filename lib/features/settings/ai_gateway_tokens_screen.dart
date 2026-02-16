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
  int? _monthlyLimit;
  int? _periodUsedTokens;
  String? _periodStart;
  String? _periodEnd;
  Map<String, dynamic>? _byDay;
  String? _usageError;
  bool _showBreakdown = false;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage({bool breakdown = false}) async {
    setState(() {
      _usageLoading = true;
      _usageError = null;
    });
    final result = await _gatewayService.getUsage(breakdown: breakdown);
    if (mounted) {
      setState(() {
        _usageLoading = false;
        _inputTokens = result.inputTokens ?? 0;
        _outputTokens = result.outputTokens ?? 0;
        _totalTokens = result.totalTokens ?? 0;
        _monthlyLimit = result.monthlyLimit;
        _periodUsedTokens = result.periodUsedTokens;
        _periodStart = result.periodStart;
        _periodEnd = result.periodEnd;
        _byDay = result.byDay;
        _usageError = result.error;
        _showBreakdown = breakdown && (_byDay != null && _byDay!.isNotEmpty);
      });
    }
  }

  String _formatNumber(int? value) {
    if (value == null) return '0';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  String? _formatDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiGatewayToken),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _usageLoading ? null : () => _loadUsage(breakdown: _showBreakdown),
            tooltip: 'Обновить статистику',
          ),
        ],
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
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _usageError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            )
          else ...[
            // Monthly limit progress
            if (_monthlyLimit != null && _monthlyLimit! > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly limit',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${_formatNumber(_periodUsedTokens ?? 0)} / ${_formatNumber(_monthlyLimit)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _monthlyLimit! > 0
                            ? ((_periodUsedTokens ?? 0) / _monthlyLimit!).clamp(0.0, 1.0)
                            : 0.0,
                        minHeight: 8,
                      ),
                      if (_periodStart != null || _periodEnd != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _periodStart != null && _periodEnd != null
                              ? 'Period: ${_formatDate(_periodStart)} - ${_formatDate(_periodEnd)}'
                              : _periodEnd != null
                                  ? 'Resets on ${_formatDate(_periodEnd)}'
                                  : '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Total usage stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total usage',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.aiGatewayUsageStats(
                        _formatNumber(_inputTokens),
                        _formatNumber(_outputTokens),
                        _formatNumber(_totalTokens),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            // Daily breakdown toggle
            if (_byDay != null || _periodEnd != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _loadUsage(breakdown: !_showBreakdown),
                icon: Icon(_showBreakdown ? Icons.expand_less : Icons.expand_more),
                label: Text(_showBreakdown ? 'Hide daily breakdown' : 'Show daily breakdown'),
              ),
            ],
            // Daily breakdown
            if (_showBreakdown && _byDay != null && _byDay!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily breakdown',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      ...(_byDay!.entries.toList()
                        ..sort((a, b) => b.key.compareTo(a.key))
                        ..take(30))
                          .map((entry) {
                        final dayData = entry.value as Map<String, dynamic>?;
                        final dayTokens = (dayData?['input_tokens'] as int? ?? 0) +
                            (dayData?['output_tokens'] as int? ?? 0);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(entry.key) ?? entry.key,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                _formatNumber(dayTokens),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
