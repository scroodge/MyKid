import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/subscription_repository.dart';
import '../../l10n/app_localizations.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _repo = SubscriptionRepository();
  SubscriptionInfo? _subscription;
  bool _loading = true;
  String? _creatingCheckoutForPlan; // 'basic' | 'premium' — only this button shows loading
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sub = await _repo.getMySubscription();
      if (mounted) {
        setState(() {
          _subscription = sub;
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

  Widget _buildPlanTrailing(String planId) {
    final l10n = AppLocalizations.of(context)!;
    final currentPlan = _subscription?.planId;
    final isCurrentPlan = currentPlan == planId;

    if (_creatingCheckoutForPlan == planId) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (isCurrentPlan) {
      return OutlinedButton(
        onPressed: () => _showManageSubscription(),
        child: Text(l10n.manageSubscription),
      );
    }
    if (currentPlan == 'basic' && planId == 'premium') {
      return FilledButton(
        onPressed: _creatingCheckoutForPlan != null ? null : () => _startTrial('premium'),
        child: Text(l10n.upgradeToPremium),
      );
    }
    if (_subscription == null || !_subscription!.isActive) {
      return FilledButton(
        onPressed: _creatingCheckoutForPlan != null ? null : () => _startTrial(planId),
        child: Text(l10n.startTrial7Days),
      );
    }
    return const SizedBox.shrink();
  }

  void _showManageSubscription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.manageSubscription),
        content: Text(AppLocalizations.of(context)!.manageSubscriptionDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _startTrial(String planId) async {
    setState(() {
      _creatingCheckoutForPlan = planId;
      _error = null;
    });
    try {
      try {
        await Supabase.instance.client.auth.refreshSession();
      } catch (_) {
        // Refresh failed (e.g. expired refresh token) — will check session below
      }
      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null || session.accessToken.isEmpty) {
        if (mounted) {
        setState(() {
          _creatingCheckoutForPlan = null;
          _error = AppLocalizations.of(context)!.sessionExpiredSignInAgain;
        });
        }
        return;
      }

      final res = await Supabase.instance.client.functions.invoke(
        'create-checkout',
        body: {'plan_id': planId},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (!mounted) return;
      if (res.status != 200) {
        final err = res.data?['error'] ?? res.data?.toString() ?? 'Checkout failed';
        final isUnauthorized = res.status == 401;
        setState(() {
          _creatingCheckoutForPlan = null;
          _error = isUnauthorized
              ? AppLocalizations.of(context)!.sessionExpiredCheckProject
              : err.toString();
        });
        return;
      }
      final url = res.data?['url'] as String?;
      if (url == null || url.isEmpty) {
        setState(() {
          _creatingCheckoutForPlan = null;
          _error = 'No checkout URL';
        });
        return;
      }
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        setState(() => _creatingCheckoutForPlan = null);
        if (launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.subscriptionSuccess)),
          );
          _load();
        } else {
          setState(() {
            _creatingCheckoutForPlan = null;
            _error = 'Could not open browser';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creatingCheckoutForPlan = null;
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
        title: Text(l10n.subscription),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                      ),
                    ),
                  ),
                if (_subscription != null && _subscription!.isActive) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _subscription!.planId == 'premium' ? l10n.planPremium : l10n.planBasic,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subscription!.planId == 'premium'
                                ? l10n.planPremiumDescription
                                : l10n.planBasicDescription,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _subscription!.status == 'trialing'
                                ? 'Trial until ${_subscription!.trialEndsAt?.toIso8601String().split('T').first ?? '—'}'
                                : 'Active',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  l10n.subscriptionSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(l10n.planBasic),
                        subtitle: Text(l10n.planBasicDescription),
                        trailing: _buildPlanTrailing('basic'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(l10n.planPremium),
                        subtitle: Text(l10n.planPremiumDescription),
                        trailing: _buildPlanTrailing('premium'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
