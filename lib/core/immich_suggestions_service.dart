import '../data/child.dart';
import 'immich_service.dart';
import 'photo_library_scanner.dart';

/// Fetches photo suggestions from Immich People API for children linked to Immich persons.
class ImmichSuggestionsService {
  ImmichSuggestionsService([ImmichService? immich])
      : _immich = immich ?? ImmichService();

  final ImmichService _immich;

  /// Fetches suggestions from Immich for children with immichPersonId.
  /// Returns list of PhotoSuggestion (with immichAssetId, thumbnailUrl).
  Future<List<PhotoSuggestion>> fetchForChildren(
    List<Child> children,
  ) async {
    final client = await _immich.getClient();
    if (client == null) return [];

    final suggestions = <PhotoSuggestion>[];
    for (final child in children) {
      final personId = child.immichPersonId;
      if (personId == null || personId.isEmpty) continue;

      final assets = await client.getPersonAssets(personId);
      for (final asset in assets) {
        if (asset.type != 'IMAGE') continue;
        final date = asset.localDateTime ?? asset.fileCreatedAt ?? DateTime.now();
        final thumbnailUrl = client.getAssetThumbnailUrlWithKey(
          asset.id,
          size: 'thumbnail',
        );
        suggestions.add(PhotoSuggestion(
          immichAssetId: asset.id,
          child: child,
          date: date,
          thumbnailUrl: thumbnailUrl,
        ));
      }
    }
    return suggestions;
  }
}
