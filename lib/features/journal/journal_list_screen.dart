import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/journal_entry.dart';
import '../../data/journal_repository.dart';
import '../../data/local/journal_cache.dart';
import '../import/batch_import_screen.dart';
import 'journal_entry_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final _repo = JournalRepository();
  List<JournalEntry> _entries = [];
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
      final list = await _repo.getEntries(limit: 100);
      await JournalCache.putAll(list);
      if (mounted) setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _entries = JournalCache.getAll();
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEntry(JournalEntry entry) async {
    final updated = await Navigator.of(context).push<JournalEntry?>(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(entry: entry),
      ),
    );
    if (updated != null) _load();
  }

  Future<void> _createEntry() async {
    final entry = JournalEntry(
      id: '',
      userId: Supabase.instance.client.auth.currentUser!.id,
      date: DateTime.now(),
      text: '',
      assets: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final created = await Navigator.of(context).push<JournalEntry?>(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(entry: entry, isNew: true),
      ),
    );
    if (created != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyKid Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Batch import',
            onPressed: () => Navigator.of(context).pushNamed('/import'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.book, size: 64, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            const Text('No entries yet'),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: _createEntry,
                              icon: const Icon(Icons.add),
                              label: const Text('Add first entry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final e = _entries[index];
                          return ListTile(
                            title: Text(
                              e.text.isEmpty ? 'No title' : (e.text.length > 80 ? '${e.text.substring(0, 80)}...' : e.text),
                            ),
                            subtitle: Text(_formatDate(e.date)),
                            trailing: e.assets.isNotEmpty
                                ? Text('${e.assets.length} photo(s)', style: Theme.of(context).textTheme.bodySmall)
                                : null,
                            onTap: () => _openEntry(e),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createEntry,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(d.year, d.month, d.day);
    if (entryDay == today) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (entryDay == yesterday) return 'Yesterday';
    return '${d.day}.${d.month}.${d.year}';
  }
}
