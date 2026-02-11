import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/photo_library_scanner.dart';
import '../../l10n/app_localizations.dart';

/// Displays a single photo suggestion with preview and create-entry action.
class SuggestionItem extends StatelessWidget {
  const SuggestionItem({
    super.key,
    required this.suggestion,
    required this.onCreateEntry,
  });

  final PhotoSuggestion suggestion;
  final VoidCallback onCreateEntry;

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
    final child = suggestion.child;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onCreateEntry,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: suggestion.thumbnailBytes != null
                    ? Image.memory(
                        suggestion.thumbnailBytes!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : suggestion.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: suggestion.thumbnailUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 72,
                              height: 72,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.photo,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.photo,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          )
                        : Container(
                            width: 72,
                            height: 72,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.photo,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      child.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _formatDate(context, suggestion.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onCreateEntry,
                child: Text(AppLocalizations.of(context)!.createEntryFromSuggestion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
