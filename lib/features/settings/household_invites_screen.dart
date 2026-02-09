import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/household_invite_repository.dart';
import '../../data/household_repository.dart';
import '../../l10n/app_localizations.dart';

class HouseholdInvitesScreen extends StatefulWidget {
  const HouseholdInvitesScreen({super.key});

  @override
  State<HouseholdInvitesScreen> createState() => _HouseholdInvitesScreenState();
}

class _HouseholdInvitesScreenState extends State<HouseholdInvitesScreen> {
  final _inviteRepo = HouseholdInviteRepository();
  final _householdRepo = HouseholdRepository();
  List<HouseholdInvite> _invites = [];
  bool _loading = true;
  String? _householdId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final householdId = await _householdRepo.getMyFirstHouseholdId();
      if (householdId == null || !mounted) {
        setState(() {
          _loading = false;
          _householdId = null;
        });
        return;
      }
      final invites = await _inviteRepo.getInvitesForHousehold(householdId);
      if (mounted) {
        setState(() {
          _invites = invites;
          _householdId = householdId;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _createInvite() async {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inviteToFamily),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: l10n.inviteEmail,
            hintText: l10n.inviteEmailHint,
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(l10n.createInvite),
          ),
        ],
      ),
    );
    if (confirmed != true || _householdId == null) return;
    final email = emailController.text.trim().toLowerCase();
    if (!email.contains('@')) return;
    try {
      final invite = await _inviteRepo.createInvite(householdId: _householdId!, email: email);
      if (invite != null && mounted) {
        await _load();
        _showInviteCreated(invite);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showInviteCreated(HouseholdInvite invite) async {
    final l10n = AppLocalizations.of(context)!;
    final link = 'mykid://invite/${invite.token}';
    final code = invite.token.substring(0, 8).toUpperCase();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inviteCreated),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l10n.inviteLink}:', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(link, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text('${l10n.inviteCode}:', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(code, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.inviteCopied)),
                      );
                    },
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(l10n.copyInviteLink),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.inviteCopied)),
                      );
                    },
                    icon: const Icon(Icons.tag, size: 18),
                    label: Text(l10n.copyInviteCode),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelInvite(HouseholdInvite invite) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelInvite),
        content: Text(l10n.cancelInviteConfirm(invite.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await _inviteRepo.deleteInvite(invite.id);
    if (success && mounted) {
      await _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel invite')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inviteToFamily),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _householdId == null ? null : _createInvite,
            tooltip: l10n.createInvite,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _householdId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.family_restroom, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'Create a household first',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : _invites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline, size: 64, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noInvites,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _createInvite,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.createInvite),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ListTile(
                          title: Text(l10n.pendingInvites),
                          trailing: FilledButton.icon(
                            onPressed: _createInvite,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.createInvite),
                          ),
                        ),
                        const Divider(),
                        ..._invites.map((invite) {
                          final expired = invite.isExpired;
                          final expiresStr = DateFormat.yMMMd().add_jm().format(invite.expiresAt);
                          return ListTile(
                            title: Text(invite.email),
                            subtitle: Text(
                              expired
                                  ? 'Expired'
                                  : l10n.inviteExpires(expiresStr),
                              style: TextStyle(
                                color: expired
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.cancel_outlined),
                              onPressed: expired ? null : () => _cancelInvite(invite),
                              tooltip: l10n.cancelInvite,
                            ),
                          );
                        }),
                      ],
                    ),
    );
  }
}
