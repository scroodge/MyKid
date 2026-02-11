import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/face_recognition_service.dart';
import '../../data/child.dart';
import '../../data/children_repository.dart';
import '../../data/local/face_embeddings_cache.dart';
import '../../l10n/app_localizations.dart';

/// Screen to add reference photos for a child's face recognition.
class FaceTrainingScreen extends StatefulWidget {
  const FaceTrainingScreen({super.key, this.initialChild});

  final Child? initialChild;

  @override
  State<FaceTrainingScreen> createState() => _FaceTrainingScreenState();
}

class _FaceTrainingScreenState extends State<FaceTrainingScreen> {
  final _childrenRepo = ChildrenRepository();
  final _faceService = FaceRecognitionService();
  List<Child> _children = [];
  Child? _selectedChild;
  bool _loading = true;
  bool _adding = false;
  String? _error;
  int _refCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _childrenRepo.getAll();
      Child? selected = widget.initialChild;
      if (selected != null && list.any((c) => c.id == selected!.id)) {
        // keep
      } else if (list.isNotEmpty) {
        selected = list.first;
      }
      if (mounted) {
        setState(() {
          _children = list;
          _selectedChild = selected;
          _refCount = selected != null
              ? FaceEmbeddingsCache.getForChild(selected.id).length
              : 0;
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

  Future<void> _replaceReferencePhotos() async {
    final child = _selectedChild;
    if (child == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.replaceReferencePhotosConfirm),
        content: Text(l10n.replaceReferencePhotosConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.replaceReferencePhotos),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await FaceEmbeddingsCache.removeForChild(child.id);
    if (mounted) {
      setState(() => _refCount = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.replaceReferencePhotosDone)),
      );
    }
  }

  Future<void> _pickReferencePhotos() async {
    final child = _selectedChild;
    if (child == null) return;

    setState(() {
      _adding = true;
      _error = null;
    });

    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 90, limit: 5);
      if (files.isEmpty || !mounted) {
        setState(() => _adding = false);
        return;
      }

      var added = 0;
      var skipped = 0;
      for (var i = 0; i < files.length && mounted; i++) {
        final x = files[i];
        Uint8List? bytes;
        try {
          bytes = await x.readAsBytes();
        } catch (_) {}
        if (bytes == null || bytes.isEmpty) {
          skipped++;
          continue;
        }

        final photoId = 'ref_${child.id}_${DateTime.now().millisecondsSinceEpoch}_$i';
        final fe = await _faceService.addReferencePhoto(child.id, photoId, bytes);
        if (fe != null) {
          added++;
        } else {
          skipped++;
        }
      }

      if (mounted) {
        setState(() {
          _refCount = FaceEmbeddingsCache.getForChild(child.id).length;
          _adding = false;
        });
        String message;
        if (added > 0 && skipped > 0) {
          message = 'Добавлено $added из ${files.length}. По $skipped фото лицо не распознано — выберите фото, где лицо чётко видно в фас.';
        } else if (added > 0) {
          message = 'Добавлено $added фото для распознавания';
        } else {
          message = 'Лицо не распознано. Выберите фото, где лицо чётко видно в фас и хорошо освещено.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _adding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Эталонные фото'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Сначала добавьте ребёнка в Дети',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Выберите ребёнка',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<Child>(
                      segments: _children
                          .map(
                            (c) => ButtonSegment<Child>(
                              value: c,
                              label: Text(c.name),
                            ),
                          )
                          .toList(),
                      selected: {_selectedChild ?? _children.first},
                      onSelectionChanged: (s) {
                        if (s.isNotEmpty) {
                          setState(() {
                            _selectedChild = s.first;
                            _refCount = FaceEmbeddingsCache.getForChild(s.first.id).length;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Добавьте 3–5 чётких фото лица ребёнка для распознавания.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Эталонных фото: $_refCount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _adding ? null : _pickReferencePhotos,
                            icon: _adding
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_photo_alternate),
                            label: Text(_adding ? 'Обработка…' : 'Выбрать фото'),
                          ),
                        ),
                        if (_refCount > 0) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _adding ? null : _replaceReferencePhotos,
                            child: Text(AppLocalizations.of(context)!.replaceReferencePhotos),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
    );
  }
}
