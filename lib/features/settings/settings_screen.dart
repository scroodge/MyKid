import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '1.0.0';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = _displayNameFromUser(user);
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // User block
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).pushNamed('/profile');
                if (mounted) setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName.isEmpty ? 'Profile' : displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      'Edit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Семья / Дети
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Family',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.child_care, color: Theme.of(context).colorScheme.tertiary),
                  title: const Text('Manage children'),
                  subtitle: const Text(
                    'Name, date of birth. Photos can be saved to a child\'s Immich album.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/children'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Синхронизация / Immich
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Sync',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.cloud_outlined, color: Theme.of(context).colorScheme.secondary),
                  title: const Text('Immich'),
                  subtitle: const Text('Server URL and API key'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/settings-immich'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Аккаунт
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Account',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: const Text('Sign out'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    }
                  },
                ),
              ],
            ),
          ),

          // Footer: app name + version
          const SizedBox(height: 32),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/brand/logo/mykid_logo_horizontal_dark.png'
                        : 'assets/brand/logo/mykid_logo_text_only.png',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.child_care,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MyKid Journal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Version ${SettingsScreen.appVersion}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
