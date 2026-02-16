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
  List<FaceEmbedding> _referencePhotos = [];

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
          if (selected != null) {
            _referencePhotos = FaceEmbeddingsCache.getForChild(selected.id);
            _refCount = _referencePhotos.length;
          } else {
            _referencePhotos = [];
            _refCount = 0;
          }
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
      setState(() {
        _referencePhotos = [];
        _refCount = 0;
      });
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
      final total = files.length;
      
      // Process all photos sequentially with progress feedback
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
        
        // Update count and photos list after each photo for better UX
        if (mounted) {
          setState(() {
            _referencePhotos = FaceEmbeddingsCache.getForChild(child.id);
            _refCount = _referencePhotos.length;
          });
        }
      }

      if (mounted) {
        setState(() {
          _adding = false;
        });
        String message;
        if (added > 0 && skipped > 0) {
          message = 'Добавлено $added из $total фото. По $skipped фото лицо не распознано — выберите фото, где лицо чётко видно в фас.';
        } else if (added > 0) {
          message = added == 1 
              ? 'Добавлено $added фото для распознавания'
              : 'Добавлено $added фото для распознавания';
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
                            _referencePhotos = FaceEmbeddingsCache.getForChild(s.first.id);
                            _refCount = _referencePhotos.length;
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
                    if (_referencePhotos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Добавленные фото:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _referencePhotos.length,
                          itemBuilder: (context, index) {
                            final photo = _referencePhotos[index];
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: photo.thumbnailBytes != null
                                    ? Image.memory(
                                        photo.thumbnailBytes!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.photo,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
                            label: Text(_adding ? 'Обработка…' : 'Выбрать фото (до 5)'),
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
                    if (_adding) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Обработка фото… Используются локальные ресурсы, при необходимости — сервер.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
