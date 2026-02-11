import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/household_invite_repository.dart';
import '../../data/household_repository.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class AcceptInviteScreen extends StatefulWidget {
  final String? token;

  const AcceptInviteScreen({super.key, this.token});

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final _inviteRepo = HouseholdInviteRepository();
  final _householdRepo = HouseholdRepository();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  HouseholdInvite? _invite;
  bool _isAuthenticated = false;
  static const String _pendingInviteTokenKey = 'pending_invite_token';

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadInviteToken();
  }

  Future<void> _loadInviteToken() async {
    String? token = widget.token;
    
    // If no token in widget, try to load from shared preferences (for email confirmation flow)
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_pendingInviteTokenKey);
      if (token != null) {
        // Clear saved token after loading
        await prefs.remove(_pendingInviteTokenKey);
      }
    }
    
    if (token != null) {
      _loadInvite(token);
    }
  }

  void _checkAuth() {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isAuthenticated = user != null;
    });
    // Listen for auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (mounted) {
        setState(() {
          _isAuthenticated = event.session?.user != null;
        });
        // If user just logged in and we have an invite, try to accept it
        if (_isAuthenticated && _invite != null && !_loading) {
          _acceptInvite();
        }
      }
    });
  }

  Future<void> _checkAuthAndAccept() async {
    // Check if user is now authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _invite != null && !_loading) {
      // User is authenticated and we have invite - accept it
      await _acceptInvite();
    } else if (user != null && widget.token != null) {
      // User is authenticated but invite not loaded - reload it
      await _loadInvite(widget.token!);
      if (_invite != null && !_loading) {
        await _acceptInvite();
      }
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

  /// Pops back to home so that Settings/Home reload household and children.
  void _goHomeAndShowSnackBar(String message) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Verifies that user is actually in a household after accepting invite.
  /// Returns true if user is now a member, false otherwise.
  Future<bool> _verifyHouseholdMembership() async {
    try {
      final householdId = await _householdRepo.getMyFirstHouseholdId();
      return householdId != null;
    } catch (e) {
      return false;
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
        // Wait a bit for DB to update, then verify membership
        await Future.delayed(const Duration(milliseconds: 500));
        final isMember = await _verifyHouseholdMembership();
        if (isMember) {
          _goHomeAndShowSnackBar(l10n.inviteAccepted);
        } else {
          // Try once more - sometimes DB needs a moment
          await Future.delayed(const Duration(milliseconds: 1000));
          final isMemberRetry = await _verifyHouseholdMembership();
          if (isMemberRetry) {
            _goHomeAndShowSnackBar(l10n.inviteAccepted);
          } else {
            // RPC said success but user is not in household - try accepting again
            final retryResult = await _inviteRepo.acceptInvite(_invite!.token);
            if (retryResult.success) {
              await Future.delayed(const Duration(milliseconds: 500));
              final isMemberAfterRetry = await _verifyHouseholdMembership();
              if (isMemberAfterRetry) {
                _goHomeAndShowSnackBar(l10n.inviteAccepted);
              } else {
                setState(() {
                  _loading = false;
                  _error = l10n.inviteAcceptedDataNotRefreshed;
                });
              }
            } else {
              _goHomeAndShowSnackBar(l10n.inviteAccepted);
            }
          }
        }
      } else {
        // Check if user is already a member
        final errorMsg = result.error ?? '';
        if (errorMsg.toLowerCase().contains('already a member') || 
            errorMsg.toLowerCase().contains('already member')) {
          // Verify user is actually a member
          await Future.delayed(const Duration(milliseconds: 500));
          final isMember = await _verifyHouseholdMembership();
          if (isMember) {
            _goHomeAndShowSnackBar(l10n.alreadyMember);
          } else {
            // RPC says "already member" but user is not - try accepting anyway
            final retryResult = await _inviteRepo.acceptInvite(_invite!.token);
            if (retryResult.success) {
              await Future.delayed(const Duration(milliseconds: 500));
              final isMemberAfterRetry = await _verifyHouseholdMembership();
              if (isMemberAfterRetry) {
                _goHomeAndShowSnackBar(l10n.inviteAccepted);
              } else {
                setState(() {
                  _loading = false;
                  _error = l10n.inviteAcceptErrorRetry;
                });
              }
            } else {
              // Still error - go home anyway, maybe user was added between calls
              _goHomeAndShowSnackBar(l10n.alreadyMember);
            }
          }
        } else {
          setState(() {
            _loading = false;
            _error = result.error ?? l10n.inviteAcceptFailed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('already a member') || errorStr.contains('already member')) {
          // Verify membership before showing "already member"
          await Future.delayed(const Duration(milliseconds: 500));
          final isMember = await _verifyHouseholdMembership();
          if (isMember) {
            _goHomeAndShowSnackBar(AppLocalizations.of(context)!.alreadyMember);
          } else {
            // Try accepting one more time
            try {
              final retryResult = await _inviteRepo.acceptInvite(_invite!.token);
              if (retryResult.success) {
                await Future.delayed(const Duration(milliseconds: 500));
                final isMemberAfterRetry = await _verifyHouseholdMembership();
                if (isMemberAfterRetry) {
                  _goHomeAndShowSnackBar(AppLocalizations.of(context)!.inviteAccepted);
                } else {
                  setState(() {
                    _loading = false;
                    _error = AppLocalizations.of(context)!.inviteAcceptErrorRestart;
                  });
                }
              } else {
                _goHomeAndShowSnackBar(AppLocalizations.of(context)!.alreadyMember);
              }
            } catch (retryError) {
              _goHomeAndShowSnackBar(AppLocalizations.of(context)!.alreadyMember);
            }
          }
        } else {
          setState(() {
            _loading = false;
            _error = e.toString();
          });
        }
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
                    Text(
                      l10n.inviteOpenLinkHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: Text(l10n.orEnterCodeManually),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: _codeController,
                                decoration: InputDecoration(
                                  labelText: l10n.inviteCode,
                                  hintText: l10n.enterInviteCodeHint,
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
                                child: Text(_loading ? l10n.searching : l10n.searchByCode),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                              l10n.invitedBy,
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
                    if (!_isAuthenticated) ...[
                      Text(
                        l10n.signInToAcceptInvite,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : () async {
                          // Navigate to signup and wait for result
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                              settings: RouteSettings(arguments: widget.token), // Pass token
                            ),
                          );
                          // After signup/login, check auth and accept invite
                          if (mounted && result == true) {
                            _checkAuthAndAccept();
                          }
                        },
                        child: Text(l10n.signUpToAccept),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading ? null : () async {
                          // Navigate to login and wait for result
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                              settings: RouteSettings(arguments: widget.token), // Pass token
                            ),
                          );
                          // After login, check auth and accept invite
                          if (mounted && result == true) {
                            _checkAuthAndAccept();
                          }
                        },
                        child: Text(l10n.alreadyHaveAccount),
                      ),
                    ] else ...[
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
                  ],
                ),
    );
  }
}
