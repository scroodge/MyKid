import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/child.dart';
import '../../l10n/app_localizations.dart';
import '../../data/children_repository.dart';
import 'child_edit_screen.dart';

class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({super.key});

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  final _repo = ChildrenRepository();
  List<Child> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.getAll();
    if (mounted) setState(() {
      _children = list;
      _loading = false;
    });
  }

  Future<void> _openEdit([Child? child]) async {
    final edited = await Navigator.of(context).push<Child?>(
      MaterialPageRoute(
        builder: (context) => ChildEditScreen(child: child),
      ),
    );
    if (edited != null) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.children),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.of(context)!.noChildrenYet),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _openEdit(),
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.addChild),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final c = _children[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: c.avatarUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Icon(
                                    Icons.child_care,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.child_care,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.child_care,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                      ),
                      title: Text(c.name),
                      subtitle: c.dateOfBirth != null
                          ? Text(AppLocalizations.of(context)!.bornDate(c.dateOfBirth!.day, c.dateOfBirth!.month, c.dateOfBirth!.year))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.deleteChild),
                              content: Text(AppLocalizations.of(context)!.deleteChildConfirm(c.name)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete)),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _repo.delete(c.id);
                            _load();
                          }
                        },
                      ),
                      onTap: () => _openEdit(c),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
