import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../core/legal_urls.dart';
import '../../l10n/app_localizations.dart';

/// Opens URL: in-app WebView for http/https (Privacy, Terms), external for mailto etc.
/// For mailto:, canLaunchUrl often returns false on simulator — we try launchUrl anyway.
Future<bool> _openUrl(String url, {bool inApp = false}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final useInApp = inApp && (uri.scheme == 'http' || uri.scheme == 'https');
  final canLaunch = uri.scheme == 'mailto' || await canLaunchUrl(uri);
  if (!canLaunch) return false;
  return launchUrl(
    uri,
    mode: useInApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
  );
}

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

String? _avatarUrlFromUser(User? user) {
  if (user == null) return null;
  final url = user.userMetadata?['avatar_url'] as String?;
  return (url != null && url.trim().isNotEmpty) ? url.trim() : null;
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
    final avatarUrl = _avatarUrlFromUser(user);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
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
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: avatarUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Icon(
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
                            displayName.isEmpty ? AppLocalizations.of(context)!.profile : displayName,
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
                      AppLocalizations.of(context)!.edit,
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
              AppLocalizations.of(context)!.family,
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
                  title: Text(AppLocalizations.of(context)!.manageChildren),
                  subtitle: Text(AppLocalizations.of(context)!.manageChildrenSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/children'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.family_restroom, color: Theme.of(context).colorScheme.secondary),
                  title: Text(AppLocalizations.of(context)!.inviteToFamily),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/household-invites'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Синхронизация / Immich
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.sync,
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
                  title: Text(AppLocalizations.of(context)!.immich),
                  subtitle: Text(AppLocalizations.of(context)!.immichSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/settings-immich'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Legal
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.legal,
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
                  leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(AppLocalizations.of(context)!.privacyPolicy),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(LegalUrls.privacyPolicy, inApp: true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(AppLocalizations.of(context)!.termsOfService),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(LegalUrls.termsOfService, inApp: true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
                  title: Text(AppLocalizations.of(context)!.support),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final opened = await _openUrl(LegalUrls.support);
                    if (!opened && context.mounted) {
                      await Clipboard.setData(const ClipboardData(text: 'support@mykidapp.com'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('support@mykidapp.com')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                  title: Text(AppLocalizations.of(context)!.licenses),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/licenses'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Аккаунт
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.account,
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
                  leading: Icon(Icons.download_outlined, color: Theme.of(context).colorScheme.secondary),
                  title: Text(AppLocalizations.of(context)!.exportMyData),
                  subtitle: Text(AppLocalizations.of(context)!.exportMyDataSubtitle),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final opened = await _openUrl(LegalUrls.dataExport);
                    if (!opened && context.mounted) {
                      await Clipboard.setData(const ClipboardData(text: 'support@mykidapp.com'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${AppLocalizations.of(context)!.exportMyDataSubtitle} support@mykidapp.com')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                  title: Text(AppLocalizations.of(context)!.deleteAccount),
                  subtitle: Text(AppLocalizations.of(context)!.deleteAccountConfirmSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.deleteAccount),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.deleteAccountConfirm),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.deleteAccountConfirmSubtitle,
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(ctx).colorScheme.error,
                            ),
                            child: Text(AppLocalizations.of(context)!.delete),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    try {
                      final res = await Supabase.instance.client.functions.invoke('delete-account');
                      if (!context.mounted) return;
                      if (res.status == 200 && res.data?['success'] == true) {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                        }
                      } else {
                        final err = res.data?['error'] ?? res.data?['details'] ?? res.data?.toString() ?? '';
                        final status = res.status;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${AppLocalizations.of(context)!.deleteAccountFailed} [$status] $err'),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    } catch (e, st) {
                      debugPrint('delete-account error: $e\n$st');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${AppLocalizations.of(context)!.deleteAccountFailed} $e'),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: Text(AppLocalizations.of(context)!.signOut),
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
                    AppLocalizations.of(context)!.appTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.version(SettingsScreen.appVersion),
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
