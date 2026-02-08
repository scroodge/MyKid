import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/immich_service.dart';
import '../../core/photo_metadata.dart';
import '../../data/journal_entry.dart';
import '../../data/journal_repository.dart';
import '../../data/local/journal_cache.dart';
import '../import/batch_import_screen.dart';
import 'journal_entry_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final _repo = JournalRepository();
  final _immich = ImmichService();
  List<JournalEntry> _entries = [];
  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getEntries(limit: 100);
      await JournalCache.putAll(list);
      if (mounted) setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _entries = JournalCache.getAll();
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEntry(JournalEntry entry) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(entry: entry),
      ),
    );
    if (result != null) _load();
  }

  Future<void> _createEntry() async {
    final source = await showModalBottomSheet<CreateEntrySource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('From camera'),
              subtitle: const Text('Take a photo now, date = today'),
              onTap: () => Navigator.pop(c, CreateEntrySource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('From gallery'),
              subtitle: const Text('Pick a photo, date & place from photo'),
              onTap: () => Navigator.pop(c, CreateEntrySource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Empty entry'),
              onTap: () => Navigator.pop(c, CreateEntrySource.empty),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    if (source == CreateEntrySource.empty) {
      await _openNewEntry(
        date: DateTime.now(),
        assets: [],
        location: null,
      );
      return;
    }

    setState(() => _creating = true);
    final picker = ImagePicker();
    if (source == CreateEntrySource.camera) {
      final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 95);
      if (x == null || !mounted) {
        setState(() => _creating = false);
        return;
      }
      Uint8List? bytes;
      try { bytes = await x.readAsBytes(); } catch (_) {}
      if (bytes == null || bytes.isEmpty) {
        setState(() => _creating = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read image')));
        return;
      }
      // Place: из EXIF снимка (если камера записала GPS) или текущая геопозиция
      String? location;
      try {
        final meta = await readPhotoMetadata(x.path);
        location = meta.location;
        if (location == null || location.isEmpty) location = await getCurrentPlaceName();
      } catch (_) {
        location = await getCurrentPlaceName();
      }
      final filename = x.name.isEmpty ? 'image.jpg' : x.name;
      final result = await _immich.uploadFromBytes(bytes, filename);
      if (!mounted) {
        setState(() => _creating = false);
        return;
      }
      setState(() => _creating = false);
      if (result.id != null) {
        await _openNewEntry(
          date: DateTime.now(),
          assets: [JournalEntryAsset(immichAssetId: result.id!)],
          location: location,
          previewBytes: {result.id!: bytes},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${result.error ?? "Unknown"}')),
        );
      }
      return;
    }

    // Gallery: pick image(s), read EXIF from first, read bytes, upload, open with date & location from first
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked == null || !mounted) {
      setState(() => _creating = false);
      return;
    }
    Uint8List? bytes;
    try { bytes = await picked.readAsBytes(); } catch (_) {}
    if (bytes == null || bytes.isEmpty) {
      setState(() => _creating = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read image')));
      return;
    }
    final meta = await readPhotoMetadata(picked.path);
    final date = meta.date ?? DateTime.now();
    final location = meta.location;
    final filename = picked.name.isEmpty ? 'image.jpg' : picked.name;
    final result = await _immich.uploadFromBytes(bytes, filename);
    if (!mounted) {
      setState(() => _creating = false);
      return;
    }
    setState(() => _creating = false);
    if (result.id != null) {
      await _openNewEntry(
        date: date,
        assets: [JournalEntryAsset(immichAssetId: result.id!)],
        location: location,
        previewBytes: {result.id!: bytes},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${result.error ?? "Unknown"}')),
      );
    }
  }

  Future<void> _openNewEntry({
    required DateTime date,
    required List<JournalEntryAsset> assets,
    String? location,
    Map<String, Uint8List>? previewBytes,
  }) async {
    final entry = JournalEntry(
      id: '',
      userId: Supabase.instance.client.auth.currentUser!.id,
      date: date,
      text: '',
      assets: assets,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      location: location,
    );
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(entry: entry, isNew: true, initialPreviewBytes: previewBytes),
      ),
    );
    if (result != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyKid Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Batch import',
            onPressed: () => Navigator.of(context).pushNamed('/import'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.book, size: 64, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            const Text('No entries yet'),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: _createEntry,
                              icon: const Icon(Icons.add),
                              label: const Text('Add first entry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final e = _entries[index];
                          return ListTile(
                            title: Text(
                              e.text.isEmpty ? 'No title' : (e.text.length > 80 ? '${e.text.substring(0, 80)}...' : e.text),
                            ),
                            subtitle: Text(_formatDate(e.date)),
                            trailing: e.assets.isNotEmpty
                                ? Text('${e.assets.length} photo(s)', style: Theme.of(context).textTheme.bodySmall)
                                : null,
                            onTap: () => _openEntry(e),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _creating ? null : _createEntry,
        child: _creating ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(d.year, d.month, d.day);
    if (entryDay == today) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (entryDay == yesterday) return 'Yesterday';
    return '${d.day}.${d.month}.${d.year}';
  }
}

enum CreateEntrySource { camera, gallery, empty }
