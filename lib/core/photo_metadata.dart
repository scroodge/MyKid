import 'dart:io';

import 'package:exif/exif.dart';
import 'package:geocoding/geocoding.dart';

/// Read date and location from image file (EXIF). Returns (date, location string or null).
Future<({DateTime? date, String? location})> readPhotoMetadata(String filePath) async {
  DateTime? date;
  String? location;
  try {
    final bytes = await File(filePath).readAsBytes();
    final data = await readExifFromBytes(bytes);
    if (data.isEmpty) return (date: null, location: null);

    // Date: EXIF DateTimeOriginal or DateTime
    final dateStr = data['EXIF DateTimeOriginal']?.printable ??
        data['Image DateTime']?.printable;
    if (dateStr != null && dateStr.isNotEmpty) {
      // Format usually "2024:01:15 14:30:00"
      final normalized = dateStr.replaceFirst(':', '-').replaceFirst(':', '-');
      date = DateTime.tryParse(normalized);
    }

    // GPS: try to get lat/long and reverse geocode to place name
    final lat = data['GPS GPSLatitude'];
    final latRef = data['GPS GPSLatitudeRef']?.printable ?? 'N';
    final lon = data['GPS GPSLongitude'];
    final lonRef = data['GPS GPSLongitudeRef']?.printable ?? 'E';
    if (lat != null && lon != null) {
      final latStr = lat.printable;
      final lonStr = lon.printable;
      if (latStr.isNotEmpty && lonStr.isNotEmpty) {
        final latVal = _gpsToDecimal(latStr, latRef == 'S');
        final lonVal = _gpsToDecimal(lonStr, lonRef == 'W');
        if (latVal != null && lonVal != null) {
          try {
            final places = await placemarkFromCoordinates(latVal, lonVal);
            if (places.isNotEmpty) {
              final p = places.first;
              final parts = [p.locality, p.administrativeArea, p.country]
                  .where((e) => e != null && e.isNotEmpty)
                  .map((e) => e!)
                  .toList();
              if (parts.isNotEmpty) location = parts.join(', ');
            }
          } catch (_) {}
        }
      }
    }
  } catch (_) {}
  return (date: date, location: location);
}

double? _gpsToDecimal(String value, bool negate) {
  // EXIF: "52/1 12/1 30/1" (rationals) or "52, 12, 30" or "52 12 30"
  try {
    final parts = value.split(RegExp(r'[\s,]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    double parsePart(String s) {
      if (s.contains('/')) {
        final n = s.split('/');
        final num = double.tryParse(n[0].trim()) ?? 0;
        final den = double.tryParse(n.length > 1 ? n[1].trim() : '1') ?? 1;
        return den != 0 ? num / den : 0;
      }
      return double.tryParse(s) ?? 0;
    }
    final deg = parsePart(parts[0]);
    final min = parts.length > 1 ? parsePart(parts[1]) : 0.0;
    final sec = parts.length > 2 ? parsePart(parts[2]) : 0.0;
    var dec = deg + min / 60 + sec / 3600;
    if (negate) dec = -dec;
    return dec;
  } catch (_) {
    return null;
  }
}
