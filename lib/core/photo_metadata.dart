import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Read date and location from image bytes (EXIF). Use for camera flow when file path may be invalid.
Future<({DateTime? date, String? location})> readPhotoMetadataFromBytes(Uint8List bytes) async {
  try {
    final data = await readExifFromBytes(bytes);
    if (data.isEmpty) return (date: null, location: null);
    return _parseExif(data);
  } catch (_) {}
  return (date: null, location: null);
}

/// Read date and location from image file (EXIF). Returns (date, location string or null).
Future<({DateTime? date, String? location})> readPhotoMetadata(String filePath) async {
  DateTime? date;
  String? location;
  try {
    final bytes = await File(filePath).readAsBytes();
    final data = await readExifFromBytes(bytes);
    if (data.isEmpty) return (date: null, location: null);
    return _parseExif(data);
  } catch (_) {}
  return (date: null, location: null);
}

Future<({DateTime? date, String? location})> _parseExif(Map<String, IfdTag> data) async {
  DateTime? date;
  String? location;
  final dateStr = data['EXIF DateTimeOriginal']?.printable ??
      data['Image DateTime']?.printable;
  if (dateStr != null && dateStr.isNotEmpty) {
    final normalized = dateStr.replaceFirst(':', '-').replaceFirst(':', '-');
    date = DateTime.tryParse(normalized);
  }
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
  return (date: date, location: location);
}

/// Ask the system to show the location permission dialog if not yet determined.
/// Call this before opening the camera so the user can allow location when taking a photo.
/// On simulator the dialog may not appear; on a real device it should show on first use.
Future<void> ensureLocationPermissionRequested() async {
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }
}

/// Get current device location as a place name (e.g. for camera photos). Returns null if permission denied or unavailable.
Future<String?> getCurrentPlaceName() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    }
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Fallback: last known position (faster, often available after permission granted)
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) return null;
    final places = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (places.isEmpty) return null;
    final p = places.first;
    final parts = [p.locality, p.administrativeArea, p.country]
        .where((e) => e != null && e.isNotEmpty)
        .map((e) => e!)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  } catch (_) {
    return null;
  }
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
