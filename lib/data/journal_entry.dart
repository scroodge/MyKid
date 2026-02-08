/// Journal entry model (matches Supabase and local DB).
class JournalEntry {
  JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.text,
    required this.assets,
    required this.createdAt,
    required this.updatedAt,
    this.childId,
    this.location,
  });

  final String id;
  final String userId;
  final DateTime date;
  final String text;
  final List<JournalEntryAsset> assets;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? childId;
  final String? location;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String().split('T').first,
        'text': text,
        'assets': assets.map((a) => a.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (childId != null) 'child_id': childId,
        if (location != null && location!.isNotEmpty) 'location': location,
      };

  static JournalEntry fromJson(Map<String, dynamic> json) {
    final assetsList = json['assets'];
    List<JournalEntryAsset> assetList = [];
    if (assetsList is List) {
      for (final a in assetsList) {
        if (a is Map<String, dynamic>) {
          assetList.add(JournalEntryAsset.fromJson(a));
        }
      }
    }
    return JournalEntry(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      text: json['text'] as String? ?? '',
      assets: assetList,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      childId: json['child_id'] as String?,
      location: json['location'] as String?,
    );
  }
}

class JournalEntryAsset {
  JournalEntryAsset({
    required this.immichAssetId,
    this.caption,
  });

  final String immichAssetId;
  final String? caption;

  Map<String, dynamic> toJson() => {
        'immichAssetId': immichAssetId,
        if (caption != null && caption!.isNotEmpty) 'caption': caption,
      };

  static JournalEntryAsset fromJson(Map<String, dynamic> json) {
    return JournalEntryAsset(
      immichAssetId: json['immichAssetId'] as String? ?? '',
      caption: json['caption'] as String?,
    );
  }
}
