import 'package:flutter/material.dart';

import '../../data/household_invite_repository.dart';
import '../../l10n/app_localizations.dart';

class AcceptInviteScreen extends StatefulWidget {
  final String? token;

  const AcceptInviteScreen({super.key, this.token});

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final _inviteRepo = HouseholdInviteRepository();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  HouseholdInvite? _invite;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _loadInvite(widget.token!);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadInvite(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invite = await _inviteRepo.getInviteByToken(token);
      if (!mounted) return;
      if (invite == null) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context)!.inviteNotFound;
        });
        return;
      }
      if (invite.isExpired) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context)!.inviteNotFound;
        });
        return;
      }
      setState(() {
        _loading = false;
        _invite = invite;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _acceptInvite() async {
    if (_invite == null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final result = await _inviteRepo.acceptInvite(_invite!.token);
      if (!mounted) return;
      if (result.success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.inviteAccepted)),
        );
      } else {
        setState(() {
          _loading = false;
          _error = result.error ?? l10n.inviteAcceptFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _searchByCode() async {
    final code = _codeController.text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (code.length < 8) {
      setState(() => _error = AppLocalizations.of(context)!.inviteCodeTooShort);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invite = await _inviteRepo.getInviteByCode(code);
      if (!mounted) return;
      if (invite == null) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context)!.inviteNotFound;
        });
        return;
      }
      if (invite.isExpired) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context)!.inviteNotFound;
        });
        return;
      }
      setState(() {
        _loading = false;
        _invite = invite;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.acceptInvite),
      ),
      body: _loading && _invite == null
          ? const Center(child: CircularProgressIndicator())
          : _invite == null
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Icon(Icons.mail_outline, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      l10n.acceptInviteTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.acceptInviteDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: l10n.inviteCode,
                        hintText: 'Enter 8-character code',
                        prefixIcon: const Icon(Icons.tag),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      onPressed: _loading ? null : _searchByCode,
                      child: Text(_loading ? l10n.testing : 'Search'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Or use the invite link you received',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Icon(Icons.family_restroom, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      l10n.acceptInviteTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.acceptInviteDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invited by:',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _invite!.email,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      onPressed: _loading ? null : _acceptInvite,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.acceptInvite),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
    );
  }
}
