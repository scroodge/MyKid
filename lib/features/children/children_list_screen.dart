import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/child.dart';
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
    if (edited != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Children'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No children yet'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _openEdit(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add child'),
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
                      title: Text(c.name),
                      subtitle: c.dateOfBirth != null
                          ? Text('Born ${DateFormat.yMMMd().format(c.dateOfBirth!)}')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete child?'),
                              content: Text('Remove "${c.name}"? Journal entries will not be deleted.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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
