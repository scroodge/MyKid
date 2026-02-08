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
  });

  final JournalEntry entry;
  final bool isNew;

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late TextEditingController _textController;
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

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entry.text);
    _date = widget.entry.date;
    _assets = List.from(widget.entry.assets);
    _selectedChildId = widget.entry.childId;
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final list = await _childrenRepo.getAll();
    if (mounted) setState(() => _children = list);
  }

  @override
  void dispose() {
    _textController.dispose();
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
    setState(() => _uploading = true);
    final result = await _immich.uploadFromXFile(x);
    if (mounted) {
      setState(() => _uploading = false);
      if (result.id != null) {
        setState(() => _assets = [..._assets, JournalEntryAsset(immichAssetId: result.id!)]);
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
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isNew) {
        final created = await _repo.createEntry(
          date: _date,
          text: _textController.text.trim(),
          assets: _assets,
          childId: _selectedChildId,
        );
        if (mounted && created != null) Navigator.of(context).pop(created);
      } else {
        final updated = await _repo.updateEntry(
          widget.entry.id,
          date: _date,
          text: _textController.text.trim(),
          assets: _assets,
          childId: _selectedChildId,
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
    setState(() => _assets = List.from(_assets)..removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New entry' : 'Entry'),
        actions: [
          if (!widget.isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete entry?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _repo.deleteEntry(widget.entry.id);
                  if (mounted) Navigator.of(context).pop(true);
                }
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
          const Text('Child (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String?>(
            value: _selectedChildId,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('— None —')),
              ..._children.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => setState(() => _selectedChildId = v),
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
                  childAspectRatio: 1,
                  children: _assets.asMap().entries.map((e) {
                    final url = client.getAssetThumbnailUrl(e.value.immichAssetId);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: url,
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
