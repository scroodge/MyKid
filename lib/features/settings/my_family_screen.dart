import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/household_repository.dart';
import '../../l10n/app_localizations.dart';

/// Shows current user's family: name and members. Shown when user is in a household.
class MyFamilyScreen extends StatefulWidget {
  const MyFamilyScreen({super.key});

  @override
  State<MyFamilyScreen> createState() => _MyFamilyScreenState();
}

class _MyFamilyScreenState extends State<MyFamilyScreen> {
  final _householdRepo = HouseholdRepository();
  String? _householdId;
  String? _householdName;
  List<({String userId, String role})> _members = [];
  bool _loading = true;
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
      final householdId = await _householdRepo.getMyFirstHouseholdId();
      if (householdId == null || !mounted) {
        setState(() {
          _loading = false;
          _householdId = null;
          _householdName = null;
          _members = [];
        });
        return;
      }
      final name = await _householdRepo.getHouseholdName(householdId);
      final members = await _householdRepo.getHouseholdMembers(householdId);
      if (mounted) {
        setState(() {
          _householdId = householdId;
          _householdName = name;
          _members = members;
          _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myFamily),
        actions: [
          if (_householdId != null)
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/household-invites').then((_) => _load()),
              child: Text(l10n.inviteToFamily),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _householdId == null
                  ? Center(
                      child: Text(
                        l10n.inviteToFamily,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.householdName,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _householdName ?? l10n.family,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            l10n.familyMembers,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Card(
                          child: Column(
                            children: [
                              for (var i = 0; i < _members.length; i++) ...[
                                if (i > 0) const Divider(height: 1),
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _members[i].role == 'owner'
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      _members[i].role == 'owner' ? Icons.star : Icons.person,
                                      color: _members[i].role == 'owner'
                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  title: Text(
                                    _members[i].userId == currentUserId
                                        ? '${_members[i].role == 'owner' ? l10n.householdMemberRoleOwner : l10n.householdMemberRoleMember} (${l10n.you})'
                                        : (_members[i].role == 'owner' ? l10n.householdMemberRoleOwner : l10n.householdMemberRoleMember),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
