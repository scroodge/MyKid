import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../../core/immich_client.dart';
import '../../core/immich_service.dart';
import '../../data/child.dart';
import '../../data/children_repository.dart';
import '../../data/journal_entry.dart';
import '../../data/journal_repository.dart';
import '../../l10n/app_localizations.dart';

/// Single pending attachment (bytes + filename) before upload to Immich.
typedef PendingAttachment = ({Uint8List bytes, String filename});

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({
    super.key,
    required this.entry,
    this.isNew = false,
    this.initialPreviewBytes,
    this.initialPendingAttachments,
  });

  final JournalEntry entry;
  final bool isNew;
  /// Preview bytes for assets (e.g. when opening after "From camera" from list)
  final Map<String, Uint8List>? initialPreviewBytes;
  /// Photos passed from list/home when creating from camera/gallery — uploaded to Immich only on Save.
  final List<PendingAttachment>? initialPendingAttachments;

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late TextEditingController _textController;
  late TextEditingController _locationController;
  late DateTime _date;
  late List<JournalEntryAsset> _assets;
  String? _selectedChildId;
  List<Child> _children = [];
  final _repo = JournalRepository();
  final _childrenRepo = ChildrenRepository();
  final _immich = ImmichService();
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  /// True = view mode (preview or fullscreen); false = edit form.
  bool _viewMode = false;
  /// In view mode: 'preview' = large preview + overlay; 'fullscreen' = original + Share/Back.
  String _viewModeSubState = 'preview';
  int _viewModePageIndex = 0;
  final PageController _viewModePageController = PageController();
  /// In-memory bytes for just-added photos (preview before Immich thumbnail is ready; iOS temp files disappear)
  final Map<String, Uint8List> _localPreviewBytes = {};
  /// Photos picked in this screen (or passed from list/home) not yet uploaded to Immich (upload on Save).
  List<PendingAttachment> _pendingAssets = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entry.text);
    _locationController = TextEditingController(text: widget.entry.location ?? '');
    _date = widget.entry.date;
    _assets = List.from(widget.entry.assets);
    _selectedChildId = widget.entry.childId;
    if (widget.initialPreviewBytes != null) _localPreviewBytes.addAll(widget.initialPreviewBytes!);
    if (widget.initialPendingAttachments != null && widget.initialPendingAttachments!.isNotEmpty) {
      _pendingAssets = List.from(widget.initialPendingAttachments!);
    }
    _viewMode = !widget.isNew;
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final list = await _childrenRepo.getAll();
    if (!mounted) return;
    final selectedExists = _selectedChildId != null && list.any((c) => c.id == _selectedChildId);
    setState(() {
      _children = list;
      if (_selectedChildId != null && !selectedExists) _selectedChildId = null;
      if (list.length == 1 && _selectedChildId == null) _selectedChildId = list.first.id;
    });
    // When opening from gallery/camera (list): add current assets to selected child's album immediately
    if (!mounted) return;
    if (_selectedChildId != null && _assets.isNotEmpty) {
      Child? child;
      for (final c in _children) {
        if (c.id == _selectedChildId) { child = c; break; }
      }
      for (final a in _assets) {
        if (child == null) break;
        await _immich.addAssetToChildAlbum(
          child,
          a.immichAssetId,
          onAlbumCreated: (albumId) async {
            await _childrenRepo.update(child!.id, immichAlbumId: albumId);
            if (mounted) await _loadChildren();
          },
        );
        for (final c in _children) {
          if (c.id == _selectedChildId) { child = c; break; }
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _locationController.dispose();
    _viewModePageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final client = await _immich.getClient();
    if (client == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.configureImmichFirst)),
        );
      }
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppLocalizations.of(context)!.camera),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.gallery),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 95);
    if (x == null || !mounted) return;
    // Read bytes once while iOS temp file is still valid; use for both upload and preview
    Uint8List? bytes;
    try {
      bytes = await x.readAsBytes();
    } catch (_) {}
    if (bytes == null || bytes.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReadImage)));
      return;
    }
    final filename = x.name.isEmpty ? 'image.jpg' : x.name;
    if (!mounted) return;
    setState(() {
      _pendingAssets = [..._pendingAssets, (bytes: bytes!, filename: filename)];
    });
  }

  Future<void> _save() async {
    if (_children.isNotEmpty && _selectedChildId == null) {
      setState(() => _error = AppLocalizations.of(context)!.selectAChild);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Upload pending photos to Immich only when user saves (not when they just pick)
      for (var i = 0; i < _pendingAssets.length; i++) {
        if (mounted) setState(() => _uploading = true);
        final pending = _pendingAssets[i];
        final result = await _immich.uploadFromBytes(pending.bytes, pending.filename);
        if (!mounted) return;
        if (result.id != null) {
          _assets = [..._assets, JournalEntryAsset(immichAssetId: result.id!)];
          _localPreviewBytes[result.id!] = pending.bytes;
        } else {
          setState(() {
            _saving = false;
            _uploading = false;
            _error = AppLocalizations.of(context)!.uploadFailedWithError(result.error ?? 'Unknown');
          });
          return;
        }
      }
      if (_pendingAssets.isNotEmpty && mounted) {
        setState(() {
          _pendingAssets = [];
          _uploading = false;
        });
      }

      // Ensure all assets are in the selected child's Immich album (e.g. photo from gallery on list)
      if (_selectedChildId != null && _assets.isNotEmpty) {
        Child? child;
        for (final c in _children) {
          if (c.id == _selectedChildId) { child = c; break; }
        }
        for (final a in _assets) {
          if (child == null) break;
          await _immich.addAssetToChildAlbum(
            child,
            a.immichAssetId,
            onAlbumCreated: (albumId) async {
              await _childrenRepo.update(child!.id, immichAlbumId: albumId);
              if (mounted) await _loadChildren();
            },
          );
          // Refresh child ref after possibly creating album (so next iteration sees immichAlbumId)
          for (final c in _children) {
            if (c.id == _selectedChildId) { child = c; break; }
          }
        }
      }
      final location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
      if (widget.isNew) {
        final created = await _repo.createEntry(
          date: _date,
          text: _textController.text.trim(),
          assets: _assets,
          childId: _selectedChildId,
          location: location,
        );
        if (mounted && created != null) Navigator.of(context).pop(created);
      } else {
        final updated = await _repo.updateEntry(
          widget.entry.id,
          date: _date,
          text: _textController.text.trim(),
          assets: _assets,
          childId: _selectedChildId,
          location: location,
        );
        if (mounted && updated != null) Navigator.of(context).pop(updated);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removeAsset(int index) {
    setState(() {
      if (index < _assets.length) {
        final assetId = _assets[index].immichAssetId;
        _assets = List.from(_assets)..removeAt(index);
        _localPreviewBytes.remove(assetId);
      } else {
        final pendingIndex = index - _assets.length;
        if (pendingIndex >= 0 && pendingIndex < _pendingAssets.length) {
          _pendingAssets = List.from(_pendingAssets)..removeAt(pendingIndex);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_viewMode) return _buildViewMode(context);
    return _buildEditMode(context);
  }

  Widget _buildViewMode(BuildContext context) {
    if (_viewModeSubState == 'fullscreen') return _buildFullscreenView(context);
    return _buildPreviewView(context);
  }

  /// Большое превью + подпись снизу. Тап по фото → открыть оригинал.
  Widget _buildPreviewView(BuildContext context) {
    final hasPhotos = _assets.isNotEmpty;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Запись', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black54,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 26),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: () => setState(() => _viewMode = false),
          ),
        ],
      ),
      body: FutureBuilder<ImmichClient?>(
        future: _immich.getClient(),
        builder: (context, snapshot) {
          final client = snapshot.data;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhotos && client != null)
                PageView.builder(
                  controller: _viewModePageController,
                  onPageChanged: (index) => setState(() => _viewModePageIndex = index),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final a = _assets[index];
                    final localBytes = _localPreviewBytes[a.immichAssetId];
                    final imageUrl = client.getAssetThumbnailUrl(a.immichAssetId, size: 'preview');
                    return GestureDetector(
                      onTap: () => setState(() => _viewModeSubState = 'fullscreen'),
                      child: localBytes != null
                          ? Image.memory(localBytes, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              httpHeaders: {'x-api-key': client.apiKey},
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.white54),
                            ),
                    );
                  },
                )
              else if (hasPhotos)
                const Center(child: CircularProgressIndicator())
              else
                Container(color: Colors.grey.shade800, child: const Center(child: Icon(Icons.photo_library, size: 80, color: Colors.white54))),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)]),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_date.day}.${_date.month}.${_date.year}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        if (_locationController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_locationController.text.trim(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                        if (_textController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_textController.text.trim(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                        if (hasPhotos) ...[
                          const SizedBox(height: 8),
                          Text('Нажмите на фото для просмотра в полном размере', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Оригинал фото + кнопки Поделиться и Назад (назад — к превью).
  Widget _buildFullscreenView(BuildContext context) {
    final hasPhotos = _assets.isNotEmpty;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Фото', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black54,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 26),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _viewModeSubState = 'preview'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться',
            onPressed: hasPhotos ? () => _shareCurrentPhoto(context) : null,
          ),
        ],
      ),
      body: hasPhotos
          ? FutureBuilder<ImmichClient?>(
              future: _immich.getClient(),
              builder: (context, snapshot) {
                final client = snapshot.data;
                if (client == null) return const Center(child: CircularProgressIndicator());
                return PageView.builder(
                  controller: _viewModePageController,
                  onPageChanged: (index) => setState(() => _viewModePageIndex = index),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final a = _assets[index];
                    final localBytes = _localPreviewBytes[a.immichAssetId];
                    if (localBytes != null) {
                      return Image.memory(localBytes, fit: BoxFit.contain);
                    }
                    return FutureBuilder<List<int>?>(
                      future: client.downloadAsset(a.immichAssetId),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final bytes = snap.data;
                        if (bytes != null && bytes.isNotEmpty) {
                          return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain);
                        }
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image, size: 64, color: Colors.white54),
                              const SizedBox(height: 8),
                              const Text('Не загрузилось', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _shareCurrentPhoto(BuildContext context) async {
    if (_assets.isEmpty) return;
    final client = await _immich.getClient();
    if (client == null) return;
    final index = _viewModePageIndex.clamp(0, _assets.length - 1);
    final assetId = _assets[index].immichAssetId;
    final bytes = await client.downloadAsset(assetId);
    if (bytes == null || bytes.isEmpty || !mounted) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/share_${assetId.substring(0, 8)}.jpg');
    await file.writeAsBytes(bytes);
    try {
      // iOS/iPad требует sharePositionOrigin в координатах source view; rect должен быть строго внутри.
      final size = MediaQuery.sizeOf(context);
      const rectSize = 80.0;
      final left = (size.width - rectSize).clamp(0.0, size.width - rectSize);
      final top = (size.height - rectSize).clamp(0.0, size.height - rectSize) * 0.5; // по центру по вертикали
      final rect = Rect.fromLTWH(left, top, rectSize, rectSize);
      await Share.shareXFiles([XFile(file.path)], sharePositionOrigin: rect);
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  Widget _buildEditMode(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? AppLocalizations.of(context)!.newEntry : AppLocalizations.of(context)!.entry),
        actions: [
          if (!widget.isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                Child? child;
                if (widget.entry.childId != null) {
                  for (final c in _children) {
                    if (c.id == widget.entry.childId) {
                      child = c;
                      break;
                    }
                  }
                }
                final canRemoveFromAlbum = child != null &&
                    child.immichAlbumId != null &&
                    child.immichAlbumId!.isNotEmpty &&
                    widget.entry.assets.isNotEmpty;

                bool removeFromAlbum = false;
                final result = await showDialog<(bool, bool)>(
                  context: context,
                  builder: (c) => StatefulBuilder(
                    builder: (context, setDialogState) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.deleteEntry),
                      content: canRemoveFromAlbum
                          ? CheckboxListTile(
                              value: removeFromAlbum,
                              onChanged: (v) =>
                                  setDialogState(() => removeFromAlbum = v ?? false),
                              title: Text(AppLocalizations.of(context)!.alsoRemoveFromAlbum),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            )
                          : null,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, (false, false)),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, (true, removeFromAlbum)),
                          child: Text(AppLocalizations.of(context)!.delete),
                        ),
                      ],
                    ),
                  ),
                );

                if (result == null) return;
                final (confirmed, doRemoveFromAlbum) = result;
                if (!confirmed) return;

                if (doRemoveFromAlbum && child != null && widget.entry.assets.isNotEmpty) {
                  final assetIds =
                      widget.entry.assets.map((a) => a.immichAssetId).toList();
                  await _immich.removeAssetsFromChildAlbum(child, assetIds);
                }
                await _repo.deleteEntry(widget.entry.id);
                if (mounted) Navigator.of(context).pop<Object?>(true);
              },
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppLocalizations.of(context)!.date, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              child: Text('${_date.day}.${_date.month}.${_date.year}'),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.child, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(AppLocalizations.of(context)!.addChildInSettings, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _children.map((c) {
                  final selected = _selectedChildId == c.id;
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: selected,
                    onSelected: (v) => setState(() => _selectedChildId = v == true ? c.id : null),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.placeOptional, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.placeHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.description, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _textController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.descriptionHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_uploading)
            const LinearProgressIndicator(),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.photosVideos, style: const TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_assets.isEmpty && _pendingAssets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(AppLocalizations.of(context)!.noMediaAttached)),
              ),
            )
          else
            FutureBuilder<ImmichClient?>(
              future: _immich.getClient(),
              builder: (context, snapshot) {
                final client = snapshot.data;
                final totalCount = _assets.length + _pendingAssets.length;
                if (client == null) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(totalCount, (i) {
                      final label = i < _assets.length
                          ? 'Asset ${_assets[i].immichAssetId.substring(0, 8)}...'
                          : 'Pending ${i - _assets.length + 1}';
                      return Chip(
                        label: Text(label),
                        onDeleted: () => _removeAsset(i),
                      );
                    }),
                  );
                }
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: List.generate(totalCount, (i) {
                    if (i < _assets.length) {
                      final assetId = _assets[i].immichAssetId;
                      final localBytes = _localPreviewBytes[assetId];
                      final debugLabel = localBytes != null
                          ? 'local: ${localBytes.length} bytes'
                          : 'immich: ${assetId.length > 8 ? "${assetId.substring(0, 8)}..." : assetId}';
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                localBytes != null
                                    ? Image.memory(localBytes, fit: BoxFit.cover)
                                    : CachedNetworkImage(
                                        imageUrl: client.getAssetThumbnailUrl(assetId, size: 'preview'),
                                        httpHeaders: {'x-api-key': client.apiKey},
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                      ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                    onPressed: () => _removeAsset(i),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(debugLabel, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      );
                    }
                    final pendingIndex = i - _assets.length;
                    final pending = _pendingAssets[pendingIndex];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(pending.bytes, fit: BoxFit.cover),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: () => _removeAsset(i),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(AppLocalizations.of(context)!.pendingSaveToUpload, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
        ],
      ),
    );
  }
}
