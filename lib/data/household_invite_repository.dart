import 'package:supabase_flutter/supabase_flutter.dart';

/// Household invite model.
class HouseholdInvite {
  HouseholdInvite({
    required this.id,
    required this.householdId,
    required this.email,
    required this.invitedBy,
    required this.token,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String email;
  final String invitedBy;
  final String token;
  final DateTime expiresAt;
  final DateTime createdAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  static HouseholdInvite fromJson(Map<String, dynamic> json) {
    return HouseholdInvite(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      email: json['email'] as String,
      invitedBy: json['invited_by'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// CRUD for household invites.
class HouseholdInviteRepository {
  HouseholdInviteRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Creates an invite for the given household and email. Returns invite with token or null.
  Future<HouseholdInvite?> createInvite({
    required String householdId,
    required String email,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final res = await _client.from('household_invites').insert({
      'household_id': householdId,
      'email': email.trim().toLowerCase(),
      'invited_by': uid,
    }).select().single();
    return HouseholdInvite.fromJson(res as Map<String, dynamic>);
  }

  /// Lists all invites for the given household.
  Future<List<HouseholdInvite>> getInvitesForHousehold(String householdId) async {
    final res = await _client
        .from('household_invites')
        .select()
        .eq('household_id', householdId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => HouseholdInvite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets invite by token (for accept screen).
  Future<HouseholdInvite?> getInviteByToken(String token) async {
    final res = await _client
        .from('household_invites')
        .select()
        .eq('token', token)
        .maybeSingle();
    if (res == null) return null;
    return HouseholdInvite.fromJson(res as Map<String, dynamic>);
  }

  /// Deletes an invite (cancel invitation).
  Future<bool> deleteInvite(String inviteId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _client.from('household_invites').delete().eq('id', inviteId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Accepts an invite by token. Returns success status and optional error message.
  Future<({bool success, String? error, String? householdId})> acceptInvite(String token) async {
    try {
      final res = await _client.rpc('accept_household_invite', params: {'p_token': token});
      final map = res as Map<String, dynamic>;
      final success = map['success'] as bool? ?? false;
      if (success) {
        return (success: true, error: null, householdId: map['household_id'] as String?);
      } else {
        return (success: false, error: map['error'] as String? ?? 'Failed to accept invite', householdId: null);
      }
    } catch (e) {
      return (success: false, error: e.toString(), householdId: null);
    }
  }
}
