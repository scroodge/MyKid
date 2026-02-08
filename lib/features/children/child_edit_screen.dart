import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/child.dart';
import '../../data/children_repository.dart';
import '../../l10n/app_localizations.dart';

const String _avatarsBucket = 'avatars';

class ChildEditScreen extends StatefulWidget {
  const ChildEditScreen({super.key, this.child});

  final Child? child;

  @override
  State<ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends State<ChildEditScreen> {
  final _repo = ChildrenRepository();
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;
  String? _avatarUrl;
  Uint8List? _pendingAvatarBytes;

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _nameController.text = widget.child!.name;
      _dateOfBirth = widget.child!.dateOfBirth;
      _avatarUrl = widget.child!.avatarUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? get _effectiveAvatarUrl =>
      _avatarUrl ?? widget.child?.avatarUrl;

  Future<void> _pickAndCropAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = source == ImageSource.camera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 90)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (xFile == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: xFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppLocalizations.of(context)!.cropPhoto,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: AppLocalizations.of(context)!.cropPhoto,
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final bytes = await cropped.readAsBytes();
    if (bytes.isEmpty || !mounted) return;

    if (widget.child != null) {
      await _uploadChildAvatar(widget.child!.id, bytes);
    } else {
      setState(() => _pendingAvatarBytes = bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.photoWillBeSaved)),
        );
      }
    }
  }

  Future<void> _uploadChildAvatar(String childId, Uint8List bytes) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _uploadingAvatar = true;
      _error = null;
    });

    try {
      final path = 'children/${user.id}/$childId/avatar.jpg';
      await Supabase.instance.client.storage.from(_avatarsBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = Supabase.instance.client.storage
          .from(_avatarsBucket)
          .getPublicUrl(path);
      final urlWithCacheBust =
          '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      await _repo.update(childId, avatarUrl: urlWithCacheBust);
      if (mounted) {
        setState(() {
          _avatarUrl = urlWithCacheBust;
          _uploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.photoUpdated)),
        );
      }
    } on StorageException catch (e) {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
          _error = e.message.isNotEmpty
              ? e.message
              : AppLocalizations.of(context)!.uploadFailedChildAvatar;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showAvatarSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.camera),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    _error = null;

    if (widget.child == null) {
      final created = await _repo.create(name: name, dateOfBirth: _dateOfBirth);
      if (!mounted) {
        setState(() => _saving = false);
        return;
      }
      if (created == null) {
        setState(() => _saving = false);
        return;
      }
      if (_pendingAvatarBytes != null && _pendingAvatarBytes!.isNotEmpty) {
        await _uploadChildAvatar(created.id, _pendingAvatarBytes!);
        if (!mounted) {
          setState(() => _saving = false);
          return;
        }
        final updated = await _repo.get(created.id);
        setState(() => _saving = false);
        if (mounted && updated != null) Navigator.of(context).pop(updated);
      } else {
        setState(() => _saving = false);
        if (mounted) Navigator.of(context).pop(created);
      }
    } else {
      final updated = await _repo.update(
        widget.child!.id,
        name: name,
        dateOfBirth: _dateOfBirth,
      );
      if (mounted) {
        setState(() => _saving = false);
        if (updated != null) Navigator.of(context).pop(updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _effectiveAvatarUrl;
    final hasImage = effectiveUrl != null && effectiveUrl.isNotEmpty || _pendingAvatarBytes != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.child == null ? AppLocalizations.of(context)!.addChild : AppLocalizations.of(context)!.editChild),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
              child: GestureDetector(
                onTap: _uploadingAvatar ? null : _showAvatarSourceSheet,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_pendingAvatarBytes != null)
                      CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: ClipOval(
                          child: Image.memory(
                            _pendingAvatarBytes!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if (hasImage && effectiveUrl != null)
                      CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: effectiveUrl,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Icon(
                              Icons.child_care,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.child_care,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.child_care,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (_uploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                AppLocalizations.of(context)!.tapToAddOrChangePhoto,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.name,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
              _dateOfBirth == null
                  ? AppLocalizations.of(context)!.dateOfBirthOptional
                  : AppLocalizations.of(context)!.bornDate(_dateOfBirth!.day, _dateOfBirth!.month, _dateOfBirth!.year),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ?? DateTime.now(),
                firstDate: DateTime(2010),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
