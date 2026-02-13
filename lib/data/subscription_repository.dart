import 'package:supabase_flutter/supabase_flutter.dart';

/// Subscription status and plan from Stripe-managed subscriptions.
class SubscriptionInfo {
  const SubscriptionInfo({
    required this.status,
    required this.planId,
    this.trialEndsAt,
    this.currentPeriodEnd,
    this.storageLimitGb = 10,
  });

  final String status;
  final String planId;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final int storageLimitGb;

  bool get isActive =>
      status == 'trialing' || status == 'active' || status == 'past_due';
  bool get isPremium => planId == 'premium';
}

class SubscriptionRepository {
  SubscriptionRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches current user's subscription row (RLS: user sees only own row).
  Future<SubscriptionInfo?> getMySubscription() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _client
        .from('subscriptions')
        .select('status, plan_id, trial_ends_at, current_period_end, storage_limit_gb')
        .eq('user_id', uid)
        .maybeSingle();
    final map = res;
    if (map == null) return null;
    return SubscriptionInfo(
      status: map['status'] as String? ?? 'expired',
      planId: map['plan_id'] as String? ?? 'basic',
      trialEndsAt: map['trial_ends_at'] != null
          ? DateTime.tryParse(map['trial_ends_at'] as String)
          : null,
      currentPeriodEnd: map['current_period_end'] != null
          ? DateTime.tryParse(map['current_period_end'] as String)
          : null,
      storageLimitGb: (map['storage_limit_gb'] as num?)?.toInt() ?? 10,
    );
  }
}
