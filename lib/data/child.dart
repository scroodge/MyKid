/// Child profile: name, date of birth, optional Immich album id, optional Immich person id, optional avatar URL.
class Child {
  Child({
    required this.id,
    required this.userId,
    required this.name,
    this.dateOfBirth,
    this.immichAlbumId,
    this.immichPersonId,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime? dateOfBirth;
  final String? immichAlbumId;
  /// Immich person ID for face recognition — when set, suggestions come from Immich People API.
  final String? immichPersonId;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'immich_album_id': immichAlbumId,
        'immich_person_id': immichPersonId,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Age as "X лет Y мес Z дн" or "Y мес Z дн" for under 1 year. "—" if no dateOfBirth.
  String get ageDescription {
    final dob = dateOfBirth;
    if (dob == null) return '—';
    final now = DateTime.now();
    if (now.isBefore(dob)) return '—';
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    int days = now.day - dob.day;
    if (days < 0) {
      months--;
      final daysInPrevMonth = DateTime(now.year, now.month, 0).day;
      days += daysInPrevMonth - dob.day + now.day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years > 0) {
      return '$years лет $months мес $days дн';
    }
    if (months > 0) {
      return '$months мес $days дн';
    }
    return '$days дн';
  }

  static Child fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      immichAlbumId: json['immich_album_id'] as String?,
      immichPersonId: json['immich_person_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
