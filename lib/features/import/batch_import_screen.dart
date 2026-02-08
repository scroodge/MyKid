import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/immich_service.dart';
import '../../l10n/app_localizations.dart';
import '../../data/journal_entry.dart';
import '../journal/journal_entry_screen.dart';

/// Pick multiple files, upload to Immich, then create one or more journal entries.
class BatchImportScreen extends StatefulWidget {
  const BatchImportScreen({super.key});

  @override
  State<BatchImportScreen> createState() => _BatchImportScreenState();
}

class _BatchImportScreenState extends State<BatchImportScreen> {
  final _immich = ImmichService();
  final List<String> _uploadedAssetIds = [];
  bool _picking = false;
  bool _uploading = false;
  int _uploadedCount = 0;
  int _totalCount = 0;
  String? _error;

  Future<void> _pickAndUpload() async {
    final client = await _immich.getClient();
    if (client == null) {
      setState(() => _error = AppLocalizations.of(context)!.configureImmichFirst);
      return;
    }
    setState(() {
      _picking = true;
      _error = null;
    });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      setState(() => _picking = false);
      return;
    }
    final files = result.files.where((f) => f.bytes != null && f.name.isNotEmpty).toList();
    if (files.isEmpty) {
      setState(() {
        _picking = false;
        _error = AppLocalizations.of(context)!.noValidFiles;
      });
      return;
    }
    setState(() {
      _uploading = true;
      _totalCount = files.length;
      _uploadedCount = 0;
    });
    for (final pf in files) {
      final result = await _immich.uploadFromBytes(pf.bytes!, pf.name);
      if (mounted && result.id != null) {
        setState(() {
          _uploadedAssetIds.add(result.id!);
          _uploadedCount++;
        });
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  void _createSingleEntry() {
    if (_uploadedAssetIds.isEmpty) return;
    final assets = _uploadedAssetIds.map((id) => JournalEntryAsset(immichAssetId: id)).toList();
    final entry = JournalEntry(
      id: '',
      userId: '',
      date: DateTime.now(),
      text: '',
      assets: assets,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(entry: entry, isNew: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.batchImport)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppLocalizations.of(context)!.batchImportDescription,
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
          ],
          if (_uploading) ...[
            LinearProgressIndicator(value: _totalCount > 0 ? _uploadedCount / _totalCount : null),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.uploadedCount(_uploadedCount, _totalCount)),
            const SizedBox(height: 24),
          ],
          FilledButton.icon(
            onPressed: (_picking || _uploading) ? null : _pickAndUpload,
            icon: _picking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_library),
            label: Text(_picking ? AppLocalizations.of(context)!.picking : _uploading ? AppLocalizations.of(context)!.uploading : AppLocalizations.of(context)!.pickFilesAndUpload),
          ),
          if (_uploadedAssetIds.isNotEmpty) ...[
            const Divider(height: 32),
            Text(AppLocalizations.of(context)!.filesUploadedCount(_uploadedAssetIds.length)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _createSingleEntry,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.createOneEntryWithAll),
            ),
          ],
        ],
      ),
    );
  }
}
