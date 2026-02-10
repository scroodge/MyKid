import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';

/// Returns a short comma-separated description of image content using on-device ML Kit (e.g. "Child, Outdoor, Smile").
/// Use this to pass text to DeepSeek when the API does not accept images.
/// Returns null on failure (e.g. unsupported platform or ML Kit error).
Future<String?> getImageLabelsDescription(Uint8List imageBytes) async {
  if (imageBytes.isEmpty) return null;
  File? tempFile;
  try {
    final dir = await getTemporaryDirectory();
    tempFile = File('${dir.path}/mlkit_label_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);
    final inputImage = InputImage.fromFilePath(tempFile.path);
    final options = ImageLabelerOptions(confidenceThreshold: 0.4);
    final labeler = ImageLabeler(options: options);
    final labels = await labeler.processImage(inputImage);
    await labeler.close();
    if (labels.isEmpty) return null;
    // Top 12 labels, most confident first
    final sorted = List<ImageLabel>.from(labels)..sort((a, b) => b.confidence.compareTo(a.confidence));
    final top = sorted.take(12).map((l) => l.label).where((s) => s.isNotEmpty).toList();
    return top.isEmpty ? null : top.join(', ');
  } catch (_) {
    return null;
  } finally {
    try {
      if (tempFile != null && await tempFile.exists()) await tempFile.delete();
    } catch (_) {}
  }
}
