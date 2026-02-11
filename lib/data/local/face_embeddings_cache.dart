import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'face_embeddings';

/// Face embedding for a child - used for face recognition matching.
class FaceEmbedding {
  FaceEmbedding({
    required this.id,
    required this.embedding,
    required this.photoId,
    required this.createdAt,
  });

  final String id;
  final List<double> embedding;
  final String photoId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'embedding': embedding,
        'photoId': photoId,
        'createdAt': createdAt.toIso8601String(),
      };

  static FaceEmbedding fromJson(Map<String, dynamic> json) {
    final emb = json['embedding'];
    List<double> list = [];
    if (emb is List) {
      for (final e in emb) {
        if (e is num) {
          list.add(e.toDouble());
        }
      }
    }
    return FaceEmbedding(
      id: json['id'] as String? ?? '',
      embedding: list,
      photoId: json['photoId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Local cache of face embeddings per child. Stored in Hive.
class FaceEmbeddingsCache {
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  static Box<String> get _box => Hive.box<String>(_boxName);

  static List<FaceEmbedding> getForChild(String childId) {
    final json = _box.get(_key(childId));
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) =>
              e is Map<String, dynamic>
                  ? FaceEmbedding.fromJson(e)
                  : null)
          .whereType<FaceEmbedding>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> putForChild(String childId, List<FaceEmbedding> embeddings) async {
    await _box.put(
      _key(childId),
      jsonEncode(embeddings.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> addForChild(String childId, FaceEmbedding embedding) async {
    final list = getForChild(childId);
    list.add(embedding);
    await putForChild(childId, list);
  }

  static Future<void> removeForChild(String childId) async {
    await _box.delete(_key(childId));
  }

  static String _key(String childId) => 'child_$childId';
}
