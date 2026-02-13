import 'package:flutter/foundation.dart';
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
  /// Optionally sends email via Edge Function.
  Future<HouseholdInvite?> createInvite({
    required String householdId,
    required String email,
    bool sendEmail = true,
    String? inviterEmail,
    String? householdName,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final res = await _client.from('household_invites').insert({
      'household_id': householdId,
      'email': email.trim().toLowerCase(),
      'invited_by': uid,
    }).select().single();
    final invite = HouseholdInvite.fromJson(res);
    
    // Send email via Edge Function if requested
    if (sendEmail) {
      try {
        // Ensure session is valid before calling Edge Function
        final session = _client.auth.currentSession;
        if (session == null) {
          debugPrint('No active session, skipping email send');
        } else {
          final inviteCode = invite.token.substring(0, 8).toUpperCase();
          
          // Try to invoke the function
          try {
            final response = await _client.functions.invoke(
              'send-invite-email',
              body: {
                'email': email.trim().toLowerCase(),
                'inviteToken': invite.token,
                'inviteCode': inviteCode,
                if (inviterEmail != null) 'inviterEmail': inviterEmail,
                if (householdName != null && householdName.isNotEmpty) 'householdName': householdName,
              },
            );
            
            // Check if email was sent successfully
            if (response.data != null) {
              final data = response.data as Map<String, dynamic>?;
              if (data?['success'] == false) {
                debugPrint('Email service not configured or failed: ${data?['message']}');
              }
            }
          } catch (e) {
            // Email sending failed, but invite was created - log error but don't fail
            debugPrint('Failed to send invite email: $e');
          }
        }
      } catch (e) {
        // Email sending failed, but invite was created - log error but don't fail
        // The invite is still valid and can be shared manually
        debugPrint('Failed to send invite email: $e');
      }
    }
    
    return invite;
  }

  /// Lists all invites for the given household.
  Future<List<HouseholdInvite>> getInvitesForHousehold(String householdId) async {
    final res = await _client
        .from('household_invites')
        .select()
        .eq('household_id', householdId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => HouseholdInvite.fromJson(e))
        .toList();
  }

  /// Gets invite by token (for accept screen).
  Future<HouseholdInvite?> getInviteByToken(String token) async {
    try {
      // Ensure token is properly formatted UUID string
      final cleanToken = token.trim().replaceAll('"', '').replaceAll("'", '');
      final res = await _client
          .from('household_invites')
          .select()
          .eq('token', cleanToken)
          .maybeSingle();
      if (res == null) return null;
      return HouseholdInvite.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  /// Gets invite by 8-character code (prefix of token). Returns null if not found or expired.
  Future<HouseholdInvite?> getInviteByCode(String code) async {
    final normalized = code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalized.length < 8) return null;
    final code8 = normalized.substring(0, 8);
    try {
      final res = await _client.rpc('get_invite_token_by_code', params: {'p_code': code8});
      
      if (res == null) {
        return null;
      }
      
      // RPC returns text (UUID as string)
      String token;
      if (res is String) {
        token = res;
      } else if (res is Map) {
        // If returned as map, try to extract value
        token = res.values.first.toString();
      } else {
        token = res.toString();
      }
      
      // Clean token string
      token = token.replaceAll('"', '').replaceAll("'", '').trim();
      
      if (token.isEmpty || token == 'null') {
        return null;
      }
      
      // Get invite by token
      return await getInviteByToken(token);
    } catch (e) {
      return null;
    }
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
      final map = res;
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
