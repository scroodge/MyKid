import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Storage bucket for user avatars. Create in Dashboard: Storage → New bucket → name "avatars" → Public bucket.
const String _avatarsBucket = 'avatars';

/// Returns display name: user_metadata['full_name'] or email prefix/email.
String _displayNameFromUser(User? user) {
  if (user == null) return '';
  final meta = user.userMetadata;
  final name = meta?['full_name'] as String?;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  final email = user.email;
  if (email == null || email.isEmpty) return '';
  final prefix = email.split('@').first.trim();
  return prefix.isNotEmpty ? prefix : email;
}

/// Returns avatar URL from user_metadata['avatar_url'].
String? _avatarUrlFromUser(User? user) {
  if (user == null) return null;
  final url = user.userMetadata?['avatar_url'] as String?;
  return (url != null && url.trim().isNotEmpty) ? url.trim() : null;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _nameController = TextEditingController(
      text: _displayNameFromUser(user),
    );
    _avatarUrl = _avatarUrlFromUser(user);
  }

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
          toolbarTitle: 'Crop photo',
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop photo',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final bytes = await cropped.readAsBytes();
    if (bytes.isEmpty || !mounted) return;

    await _uploadAvatar(bytes);
  }

  Future<void> _uploadAvatar(Uint8List bytes) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _uploadingAvatar = true;
      _error = null;
    });

    try {
      final path = '${user.id}/avatar.jpg';
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

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': urlWithCacheBust}),
      );

      if (mounted) {
        setState(() {
          _avatarUrl = urlWithCacheBust;
          _uploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated')),
        );
      }
    } on StorageException catch (e) {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
          _error = e.message.isNotEmpty
              ? e.message
              : 'Upload failed. Create bucket "$_avatarsBucket" in Supabase Storage (public).';
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
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
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
    _error = null;
    final name = _nameController.text.trim();
    final data = <String, dynamic>{
      'full_name': name.isEmpty ? null : name,
      if (_avatarUrl != null) 'avatar_url': _avatarUrl,
    };
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: data),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final avatarUrl = _avatarUrl ?? _avatarUrlFromUser(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
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
                  if (avatarUrl != null && avatarUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Icon(
                            Icons.person,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme.onSurfaceVariant,
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.person,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                        Icons.person,
                        size: 48,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (_uploadingAvatar)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.transparent),
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
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color:
                              Theme.of(context).colorScheme.onPrimary,
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
              'Tap to add or change photo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Your name',
            ),
            textCapitalization: TextCapitalization.words,
            autocorrect: false,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: email,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Email',
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
            ),
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
