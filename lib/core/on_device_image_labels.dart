import 'dart:typed_data';

import 'on_device_image_labels_io.dart' if (dart.library.html) 'on_device_image_labels_stub.dart' as impl;

/// Returns a short comma-separated description of image content using on-device ML Kit when available (Android/iOS).
/// On web returns null. Use this to pass text to DeepSeek when the API does not accept images.
Future<String?> getImageLabelsDescription(Uint8List imageBytes) =>
    impl.getImageLabelsDescription(imageBytes);
