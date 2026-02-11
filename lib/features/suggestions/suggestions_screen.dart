import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/immich_service.dart';
import '../../core/immich_suggestions_service.dart';
import '../../core/photo_library_scanner.dart';
import '../../core/photo_metadata.dart';
import '../../data/child.dart';
import '../../data/children_repository.dart';
import '../../data/journal_entry.dart';
import '../../data/local/face_embeddings_cache.dart';
import '../../l10n/app_localizations.dart';
import 'face_training_screen.dart';
import 'suggestion_item.dart';

/// Screen showing photo suggestions (photos with child's face) and option to create entries.
class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({
    super.key,
    required this.onOpenNewEntry,
  });

  final void Function(JournalEntry entry, {List<({Uint8List bytes, String filename})>? initialPendingAttachments}) onOpenNewEntry;

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _childrenRepo = ChildrenRepository();
  final _scanner = PhotoLibraryScanner();
  final _immich = ImmichService();
  final _immichSuggestions = ImmichSuggestionsService();
  List<PhotoSuggestion> _suggestions = [];
  bool _loading = false;
  bool _scanning = false;
  int _scanProgress = 0;
  int _scanTotal = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  List<Child> _children = [];
  List<String> _childIdsWithEmbeddings = [];
  List<String> _childIdsWithImmichPerson = [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final children = await _childrenRepo.getAll();
      final withEmbeddings = <String>[];
      final withImmichPerson = <String>[];
      for (final c in children) {
        if (FaceEmbeddingsCache.getForChild(c.id).isNotEmpty) {
          withEmbeddings.add(c.id);
        }
        if (c.immichPersonId != null && c.immichPersonId!.isNotEmpty) {
          withImmichPerson.add(c.id);
        }
      }
      if (mounted) {
        setState(() {
          _children = children;
          _childIdsWithEmbeddings = withEmbeddings;
          _childIdsWithImmichPerson = withImmichPerson;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _stopScan() {
    _scanner.cancelScan();
  }

  bool get _hasAnySource =>
      _childIdsWithEmbeddings.isNotEmpty || _childIdsWithImmichPerson.isNotEmpty;

  Future<void> _runScan() async {
    if (!_hasAnySource) return;
    setState(() {
      _scanning = true;
      _error = null;
      _suggestions = [];
    });
    try {
      final allSuggestions = <PhotoSuggestion>[];

      if (_childIdsWithImmichPerson.isNotEmpty) {
        final immichList = await _immichSuggestions.fetchForChildren(_children);
        allSuggestions.addAll(immichList);
      }

      if (_childIdsWithEmbeddings.isNotEmpty) {
        final localSuggestions = await _scanner.scan(
          children: _children,
          childIdsWithEmbeddings: _childIdsWithEmbeddings,
          maxPhotos: 500,
          onProgress: (scanned, total) {
            if (mounted) {
              setState(() {
                _scanProgress = scanned;
                _scanTotal = total;
              });
            }
          },
          onSuggestionFound: (s) {
            if (mounted) {
              setState(() => _suggestions = [..._suggestions, s]);
            }
          },
        );
        allSuggestions.addAll(localSuggestions);
      }

      // Deduplicate by asset id (local) or immich asset id
      final seen = <String>{};
      final deduped = allSuggestions.where((s) {
        final key = s.immichAssetId ?? s.assetId ?? '';
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _suggestions = deduped;
          _scanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _scanning = false;
        });
      }
    }
  }

  Future<void> _openFaceTraining() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FaceTrainingScreen(),
      ),
    );
    _load();
  }

  Future<void> _createEntryFromSuggestion(PhotoSuggestion suggestion) async {
    final client = await _immich.getClient();
    if (client == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.configureImmichFirst)),
        );
      }
      return;
    }

    if (suggestion.isFromImmich && suggestion.immichAssetId != null) {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final entry = JournalEntry(
        id: '',
        userId: userId,
        date: suggestion.date,
        text: '',
        assets: [JournalEntryAsset(immichAssetId: suggestion.immichAssetId!)],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        childId: suggestion.child.id,
      );
      widget.onOpenNewEntry(entry);
      return;
    }

    final assetId = suggestion.assetId;
    if (assetId == null) return;
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null || !mounted) return;
    Uint8List? bytes;
    try {
      bytes = await asset.originBytes;
    } catch (_) {}
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReadImage)),
        );
      }
      return;
    }
    final meta = await readPhotoMetadataFromBytes(bytes);
    final date = meta.date ?? suggestion.date;
    String? location = meta.location;
    final filename = 'photo_${suggestion.assetId}.jpg';
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final entry = JournalEntry(
      id: '',
      userId: userId,
      date: date,
      text: '',
      assets: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      childId: suggestion.child.id,
      location: location,
    );
    widget.onOpenNewEntry(
      entry,
      initialPendingAttachments: [(bytes: bytes, filename: filename)],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (!_hasAnySource) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face_retouching_natural, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.addReferencePhotosPrompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (_children.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.linkChildToImmichPersonHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FaceTrainingScreen(),
                    ),
                  );
                  _load();
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(AppLocalizations.of(context)!.addReferencePhotosButton),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        if (_childIdsWithEmbeddings.isNotEmpty) await _runScan();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _scanning ? null : _runScan,
                    icon: const Icon(Icons.search),
                    label: Text(AppLocalizations.of(context)!.scanNow),
                  ),
                ),
                const SizedBox(width: 8),
                if (_scanning)
                  OutlinedButton(
                    onPressed: _stopScan,
                    child: Text(AppLocalizations.of(context)!.stopScan),
                  )
                else
                  IconButton(
                    onPressed: _openFaceTraining,
                    icon: const Icon(Icons.add_photo_alternate),
                    tooltip: AppLocalizations.of(context)!.addReferencePhotosButton,
                  ),
              ],
            ),
          ),
          if (_scanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _scanTotal > 0 ? _scanProgress / _scanTotal : null,
                  ),
                  const SizedBox(height: 8),
                  Text('${AppLocalizations.of(context)!.scanningPhotos} $_scanProgress / $_scanTotal'),
                  Text(
                    AppLocalizations.of(context)!.scanLimitHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_suggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        AppLocalizations.of(context)!.foundPhotosWithChild(
                          _suggestions.length,
                          _suggestions.map((s) => s.child.name).toSet().join(', '),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_suggestions.isEmpty && !_scanning)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noSuggestions,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.scanNowHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._suggestions.map(
              (s) => SuggestionItem(
                suggestion: s,
                onCreateEntry: () => _createEntryFromSuggestion(s),
              ),
            ),
        ],
      ),
    );
  }
}
