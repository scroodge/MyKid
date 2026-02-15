import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal_urls.dart';
import '../../core/mykid_api_service.dart';
import '../../l10n/app_localizations.dart';

/// Screen to request data export. Calls MyKid API (AI Gateway) and shows download link.
class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final _api = MyKidApiService();

  bool _loading = false;
  String? _error;
  String? _downloadUrl;

  Future<void> _startExport() async {
    if (!_api.isConfigured) {
      setState(() {
        _error = AppLocalizations.of(context)!.exportError;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _downloadUrl = null;
    });

    try {
      final result = await _api.exportData();
      final url = result['download_url'] as String?;
      if (mounted) {
        setState(() {
          _loading = false;
          _downloadUrl = url;
        });
        if (url != null && url.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: url));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.exportSuccess),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () async {
                    final uri = Uri.tryParse(url);
                    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is MyKidApiException ? e.message : e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportMyData),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_api.isConfigured) ...[
              Text(
                l10n.exportError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              Text(
                'MYKID_API_URL is not configured.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else if (_loading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.exportPreparing),
                  ],
                ),
              )
            else if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _startExport,
                child: const Text('Retry'),
              ),
            ] else if (_downloadUrl != null) ...[
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 48),
              const SizedBox(height: 16),
              Text(l10n.exportSuccess, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Download link copied to clipboard. You can also open it below.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(_downloadUrl!);
                  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open download link'),
              ),
            ] else
              FilledButton(
                onPressed: _startExport,
                child: Text(l10n.exportMyData),
              ),
          ],
        ),
      ),
    );
  }
}
