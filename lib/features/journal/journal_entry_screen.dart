import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/immich_client.dart';
import '../../core/immich_service.dart';
import '../../data/child.dart';
import '../../data/children_repository.dart';
import '../../data/journal_entry.dart';
import '../../data/journal_repository.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({
    super.key,
    required this.entry,
    this.isNew = false,
    this.initialPreviewBytes,
  });

  final JournalEntry entry;
  final bool isNew;
  /// Preview bytes for assets (e.g. when opening after "From camera" from list)
  final Map<String, Uint8List>? initialPreviewBytes;

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
  /// True = full-screen view with overlay; false = edit form. New entries start in edit mode.
  bool _viewMode = false;
  /// In-memory bytes for just-added photos (preview before Immich thumbnail is ready; iOS temp files disappear)
  final Map<String, Uint8List> _localPreviewBytes = {};

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entry.text);
    _locationController = TextEditingController(text: widget.entry.location ?? '');
    _date = widget.entry.date;
    _assets = List.from(widget.entry.assets);
    _selectedChildId = widget.entry.childId;
    if (widget.initialPreviewBytes != null) _localPreviewBytes.addAll(widget.initialPreviewBytes!);
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
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final client = await _immich.getClient();
    if (client == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configure Immich in Settings first')),
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
              title: const Text('Camera'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read image')));
      return;
    }
    final filename = x.name.isEmpty ? 'image.jpg' : x.name;
    setState(() => _uploading = true);
    final result = await _immich.uploadFromBytes(bytes, filename);
    if (mounted) {
      setState(() {
        _uploading = false;
        if (result.id != null) {
          _assets = [..._assets, JournalEntryAsset(immichAssetId: result.id!)];
          _localPreviewBytes[result.id!] = bytes!;
        }
      });
      if (result.id != null) {
        final childId = _selectedChildId;
        if (childId != null) {
          Child? child;
          for (final c in _children) {
            if (c.id == childId) { child = c; break; }
          }
          if (child != null) {
            final childToUpdate = child;
            await _immich.addAssetToChildAlbum(
              childToUpdate,
              result.id!,
              onAlbumCreated: (albumId) async {
                await _childrenRepo.update(childToUpdate.id, immichAlbumId: albumId);
                if (mounted) _loadChildren();
              },
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${result.error ?? "Unknown"}')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_children.isNotEmpty && _selectedChildId == null) {
      setState(() => _error = 'Select a child');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
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
    final assetId = _assets[index].immichAssetId;
    setState(() {
      _assets = List.from(_assets)..removeAt(index);
      _localPreviewBytes.remove(assetId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_viewMode) return _buildViewMode(context);
    return _buildEditMode(context);
  }

  Widget _buildViewMode(BuildContext context) {
    final hasPhotos = _assets.isNotEmpty;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Entry', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
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
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final a = _assets[index];
                    final localBytes = _localPreviewBytes[a.immichAssetId];
                    final imageUrl = client.getAssetDownloadUrl(a.immichAssetId);
                    return localBytes != null
                        ? Image.memory(localBytes, fit: BoxFit.cover)
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                httpHeaders: {'x-api-key': client.apiKey},
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (_, url, error) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.broken_image, size: 64, color: Colors.white54),
                                      const SizedBox(height: 8),
                                      Text('Не загрузилось', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: SelectableText(
                                          url ?? imageUrl,
                                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                                          maxLines: 3,
                                        ),
                                      ),
                                      if (error != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
                                          child: SelectableText(
                                            error.toString(),
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            maxLines: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Debug: путь запроса (без ключа)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black54,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: SelectableText(
                                    'DEBUG: $imageUrl',
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildEditMode(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New entry' : 'Entry'),
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
                      title: const Text('Delete entry?'),
                      content: canRemoveFromAlbum
                          ? CheckboxListTile(
                              value: removeFromAlbum,
                              onChanged: (v) =>
                                  setDialogState(() => removeFromAlbum = v ?? false),
                              title: const Text('Also remove photos from child\'s album'),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            )
                          : null,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, (false, false)),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, (true, removeFromAlbum)),
                          child: const Text('Delete'),
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
            child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Text('Child', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Add a child in Settings → Manage children', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
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
          const Text('Place (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: 'e.g. from photo or type here',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _textController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'What happened today?',
              border: OutlineInputBorder(),
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
              const Text('Photos / videos', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_assets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No media attached. Add via "Add" or batch import.')),
              ),
            )
          else
            FutureBuilder<ImmichClient?>(
              future: _immich.getClient(),
              builder: (context, snapshot) {
                final client = snapshot.data;
                if (client == null) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _assets.asMap().entries.map((e) {
                      return Chip(
                        label: Text('Asset ${e.value.immichAssetId.substring(0, 8)}...'),
                        onDeleted: () => _removeAsset(e.key),
                      );
                    }).toList(),
                  );
                }
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: _assets.asMap().entries.map((e) {
                    final assetId = e.value.immichAssetId;
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
                                      imageUrl: client.getAssetThumbnailUrl(assetId),
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
                                  onPressed: () => _removeAsset(e.key),
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
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}
