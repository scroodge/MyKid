import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/immich_client.dart';
import '../../core/immich_service.dart';
import '../../core/photo_metadata.dart';
import '../../core/selected_child_storage.dart';
import '../../data/child.dart';
import '../../data/children_repository.dart';
import '../../data/journal_entry.dart';
import '../../data/journal_repository.dart';
import '../../core/format_age.dart';
import '../../data/local/journal_cache.dart';
import '../../l10n/app_localizations.dart';
import '../journal/journal_entry_screen.dart';
import '../suggestions/suggestions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _childrenRepo = ChildrenRepository();
  final _journalRepo = JournalRepository();
  final _immich = ImmichService();
  final _selectedStorage = SelectedChildStorage();

  List<Child> _children = [];
  Child? _selectedChild;
  List<JournalEntry> _entries = [];
  bool _loadingChildren = true;
  bool _loadingEntries = true;
  bool _creating = false;
  String? _error;
  ImmichClient? _immichClient;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChildrenAndSelection();
    _loadImmichClient();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadImmichClient() async {
    final client = await _immich.getClient();
    if (mounted) setState(() => _immichClient = client);
  }

  Future<void> _loadChildrenAndSelection() async {
    setState(() => _loadingChildren = true);
    final list = await _childrenRepo.getAll();
    String? savedId = await _selectedStorage.getSelectedChildId();
    Child? selected;
    if (list.isNotEmpty) {
      if (savedId != null) {
        selected = list.cast<Child?>().firstWhere(
          (c) => c?.id == savedId,
          orElse: () => null,
        );
      }
      selected ??= list.first;
      if (savedId != selected.id) {
        await _selectedStorage.setSelectedChildId(selected.id);
      }
    }
    if (mounted) {
      setState(() {
        _children = list;
        _selectedChild = selected;
        _loadingChildren = false;
      });
      _loadEntries();
    }
  }

  Future<void> _loadEntries() async {
    if (_selectedChild == null) {
      setState(() {
        _entries = [];
        _loadingEntries = false;
      });
      return;
    }
    setState(() {
      _loadingEntries = true;
      _error = null;
    });
    try {
      final list = await _journalRepo.getEntries(
        childId: _selectedChild!.id,
        limit: 100,
      );
      await JournalCache.putAll(list);
      if (mounted) {
        setState(() {
          _entries = list;
          _loadingEntries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _entries = JournalCache.getAll();
          _error = e.toString();
          _loadingEntries = false;
        });
      }
    }
  }

  Future<void> _onSelectChild(Child child) async {
    await _selectedStorage.setSelectedChildId(child.id);
    if (!mounted) return;
    setState(() => _selectedChild = child);
    Navigator.of(context).pop();
    _loadEntries();
  }

  void _showChildPicker() {
    if (_children.isEmpty) {
      Navigator.of(context).pushNamed('/children').then((_) => _loadChildrenAndSelection());
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.selectAChild,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                final selected = _selectedChild?.id == child.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: child.avatarUrl != null && child.avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: child.avatarUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Text(
                                child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              errorWidget: (_, __, ___) => Text(
                                child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          )
                        : Text(
                            child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                  ),
                  title: Text(child.name),
                  subtitle: Text(child.ageDescription),
                  trailing: selected ? const Icon(Icons.check) : null,
                  onTap: () => _onSelectChild(child),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.manageChildren),
              onTap: () {
                Navigator.pop(c);
                Navigator.of(context).pushNamed('/children').then((_) => _loadChildrenAndSelection());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEntry(JournalEntry entry) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(entry: entry),
      ),
    );
    if (result != null) _loadEntries();
  }

  Future<void> _createEntry() async {
    final source = await showModalBottomSheet<CreateEntrySource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.fromCamera),
              subtitle: Text(AppLocalizations.of(context)!.fromCameraSubtitle),
              onTap: () => Navigator.pop(c, CreateEntrySource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.fromGallery),
              subtitle: Text(AppLocalizations.of(context)!.fromGallerySubtitle),
              onTap: () => Navigator.pop(c, CreateEntrySource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(AppLocalizations.of(context)!.emptyEntry),
              onTap: () => Navigator.pop(c, CreateEntrySource.empty),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) {
      return;
    }

    if (source == CreateEntrySource.empty) {
      await _openNewEntry(
        date: DateTime.now(),
        assets: [],
        location: null,
      );
      return;
    }

    setState(() => _creating = true);
    final picker = ImagePicker();
    if (source == CreateEntrySource.camera) {
      await ensureLocationPermissionRequested();
      final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 95);
      if (x == null || !mounted) {
        setState(() => _creating = false);
        return;
      }
      Uint8List? bytes;
      try {
        bytes = await x.readAsBytes();
      } catch (_) {}
      if (bytes == null || bytes.isEmpty) {
        setState(() => _creating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReadImage)));
        }
        return;
      }
      String? location;
      final meta = await readPhotoMetadataFromBytes(bytes);
      location = meta.location;
      if (location == null || location.isEmpty) location = await getCurrentPlaceName();
      final filename = x.name.isEmpty ? 'image.jpg' : x.name;
      if (!mounted) {
        setState(() => _creating = false);
        return;
      }
      setState(() => _creating = false);
      await _openNewEntry(
        date: DateTime.now(),
        assets: [],
        location: location,
        initialPendingAttachments: [(bytes: bytes!, filename: filename)],
      );
      return;
    }

    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked == null || !mounted) {
      setState(() => _creating = false);
      return;
    }
    Uint8List? bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (_) {}
    if (bytes == null || bytes.isEmpty) {
      setState(() => _creating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotReadImage)));
      }
      return;
    }
    final meta = await readPhotoMetadataFromBytes(bytes);
    final date = meta.date ?? DateTime.now();
    String? location = meta.location;
    if (location == null || location.isEmpty) location = await getCurrentPlaceName();
    final filename = picked.name.isEmpty ? 'image.jpg' : picked.name;
    if (!mounted) {
      setState(() => _creating = false);
      return;
    }
    setState(() => _creating = false);
    await _openNewEntry(
      date: date,
      assets: [],
      location: location,
      initialPendingAttachments: [(bytes: bytes!, filename: filename)],
    );
  }

  Future<void> _openNewEntry({
    required DateTime date,
    required List<JournalEntryAsset> assets,
    String? location,
    Map<String, Uint8List>? previewBytes,
    List<({Uint8List bytes, String filename})>? initialPendingAttachments,
  }) async {
    final entry = JournalEntry(
      id: '',
      userId: Supabase.instance.client.auth.currentUser!.id,
      date: date,
      text: '',
      assets: assets,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      location: location,
      childId: _selectedChild?.id,
    );
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(
          entry: entry,
          isNew: true,
          initialPreviewBytes: previewBytes,
          initialPendingAttachments: initialPendingAttachments,
        ),
      ),
    );
    if (result != null) _loadEntries();
  }

  void _openNewEntryFromSuggestion(
    JournalEntry entry, {
    List<({Uint8List bytes, String filename})>? initialPendingAttachments,
  }) {
    Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(
          entry: entry,
          isNew: true,
          initialPendingAttachments: initialPendingAttachments,
        ),
      ),
    ).then((result) {
      if (result != null) _loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: AppLocalizations.of(context)!.batchImportTooltip,
            onPressed: () => Navigator.of(context).pushNamed('/import'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.timeline),
            Tab(text: AppLocalizations.of(context)!.suggestionsTab),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildProfileBlock(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineContent(),
                SuggestionsScreen(
                  onOpenNewEntry: _openNewEntryFromSuggestion,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _creating ? null : _createEntry,
        child: _creating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileBlock() {
    if (_loadingChildren) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: _showChildPicker,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: _children.isEmpty
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Icon(Icons.person_add, size: 32, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.addChildPrompt,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            AppLocalizations.of(context)!.addChildPromptSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: _selectedChild!.avatarUrl != null && _selectedChild!.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _selectedChild!.avatarUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Text(
                                  _selectedChild!.name.isNotEmpty
                                      ? _selectedChild!.name[0].toUpperCase()
                                      : '?',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                errorWidget: (_, __, ___) => Text(
                                  _selectedChild!.name.isNotEmpty
                                      ? _selectedChild!.name[0].toUpperCase()
                                      : '?',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ),
                            )
                          : Text(
                              _selectedChild!.name.isNotEmpty
                                  ? _selectedChild!.name[0].toUpperCase()
                                  : '?',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedChild!.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            formatAge(context, _selectedChild!.dateOfBirth),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTimelineContent() {
    if (_selectedChild == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.child_care, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.selectChildAbove),
          ],
        ),
      );
    }
    if (_loadingEntries) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadEntries, child: Text(AppLocalizations.of(context)!.retry)),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEntries,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noEntriesYet),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _createEntry,
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.addEntry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return _TimelineThumbnail(
            entry: entry,
            immichClient: _immichClient,
            onTap: () => _openEntry(entry),
          );
        },
      ),
    );
  }
}

class _TimelineThumbnail extends StatelessWidget {
  const _TimelineThumbnail({
    required this.entry,
    required this.immichClient,
    required this.onTap,
  });

  final JournalEntry entry;
  final ImmichClient? immichClient;
  final VoidCallback onTap;

  String _formatDate(BuildContext context, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(d.year, d.month, d.day);
    final l10n = AppLocalizations.of(context)!;
    if (entryDay == today) return l10n.today;
    final yesterday = today.subtract(const Duration(days: 1));
    if (entryDay == yesterday) return l10n.yesterday;
    return '${d.day}.${d.month}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = entry.assets.isNotEmpty;
    final assetId = hasPhoto ? entry.assets.first.immichAssetId : null;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto && immichClient != null && assetId != null)
                CachedNetworkImage(
                  imageUrl: immichClient!.getAssetThumbnailUrl(assetId),
                  httpHeaders: {'x-api-key': immichClient!.apiKey},
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => _placeholder(context),
                )
              else
                _placeholder(context),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                    ),
                  ),
                  child: Text(
                    _formatDate(context, entry.date),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.photo_library,
          size: 40,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

enum CreateEntrySource { camera, gallery, empty }
