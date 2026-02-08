/// Child profile: name, date of birth, optional Immich album id.
class Child {
  Child({
    required this.id,
    required this.userId,
    required this.name,
    this.dateOfBirth,
    this.immichAlbumId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime? dateOfBirth;
  final String? immichAlbumId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'immich_album_id': immichAlbumId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static Child fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      immichAlbumId: json['immich_album_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
