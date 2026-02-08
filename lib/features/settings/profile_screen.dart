import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _nameController = TextEditingController(
      text: _displayNameFromUser(user),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _error = null;
    final name = _nameController.text.trim();
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': name.isEmpty ? null : name}),
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
            child: CircleAvatar(
              radius: 48,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person,
                size: 48,
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
