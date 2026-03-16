import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

final locationServiceProvider = Provider<LocationService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return LocationService(client);
});

enum LocationLookupFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  positionUnavailable,
}

class LocationLookupResult {
  const LocationLookupResult({
    required this.ok,
    this.locationText,
    this.failure,
    this.error,
  });

  final bool ok;
  final String? locationText;
  final LocationLookupFailure? failure;
  final Object? error;
}

class LocationService {
  LocationService(this._client);

  static const _reverseGeocodeUrl =
      'https://nominatim.openstreetmap.org/reverse';

  final http.Client _client;

  Future<LocationLookupResult> lookupCurrentLocation({
    required Locale locale,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationLookupResult(
        ok: false,
        failure: LocationLookupFailure.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationLookupResult(
        ok: false,
        failure: LocationLookupFailure.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationLookupResult(
        ok: false,
        failure: LocationLookupFailure.permissionDeniedForever,
      );
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      position = await Geolocator.getLastKnownPosition();
    } catch (error) {
      position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        return LocationLookupResult(
          ok: false,
          failure: LocationLookupFailure.positionUnavailable,
          error: error,
        );
      }
    }

    if (position == null) {
      return const LocationLookupResult(
        ok: false,
        failure: LocationLookupFailure.positionUnavailable,
      );
    }

    final address = await _reverseGeocode(position, locale);

    return LocationLookupResult(
      ok: true,
      locationText: address ?? _formatCoordinates(position, locale),
    );
  }

  Future<String?> _reverseGeocode(Position position, Locale locale) async {
    try {
      final response = await _client.get(
        Uri.parse(_reverseGeocodeUrl).replace(
          queryParameters: {
            'format': 'jsonv2',
            'lat': position.latitude.toString(),
            'lon': position.longitude.toString(),
            'zoom': '18',
            'addressdetails': '1',
            'accept-language': _acceptLanguage(locale),
          },
        ),
        headers: const {
          'User-Agent': 'diary-mvp/0.1 (location lookup)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 400) {
        return null;
      }

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
      if (decoded == null) return null;

      final address = decoded['address'];
      if (address is Map) {
        final formatted = _formatAddress(
          address.cast<String, dynamic>(),
          locale,
        );
        if (formatted.isNotEmpty) return formatted;
      }

      final displayName = decoded['display_name'];
      if (displayName is String && displayName.trim().isNotEmpty) {
        return _shortenDisplayName(displayName.trim(), locale);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _acceptLanguage(Locale locale) {
    return locale.languageCode == 'zh' ? 'zh-CN' : 'en-US';
  }

  String _formatAddress(Map<String, dynamic> address, Locale locale) {
    final isChinese = locale.languageCode == 'zh';
    final locality = _firstNonEmpty(
      address,
      const ['city', 'town', 'village', 'municipality', 'county'],
    );
    final district = _firstNonEmpty(
      address,
      const ['city_district', 'district', 'suburb', 'borough', 'county'],
    );
    final road = _firstNonEmpty(
      address,
      const ['road', 'neighbourhood', 'quarter', 'hamlet'],
    );
    final state = _firstNonEmpty(
      address,
      const ['state', 'region', 'province'],
    );
    final country = _firstNonEmpty(address, const ['country']);

    final rawParts = isChinese
        ? [state, locality, district, road, country]
        : [road, district, locality, state, country];
    final parts = <String>[];
    for (final part in rawParts) {
      if (part == null || part.isEmpty || parts.contains(part)) {
        continue;
      }
      parts.add(part);
      if (parts.length == 3) break;
    }

    return isChinese ? parts.join(' ') : parts.join(', ');
  }

  String? _firstNonEmpty(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _shortenDisplayName(String value, Locale locale) {
    final isChinese = locale.languageCode == 'zh';
    final parts = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);
    return isChinese ? parts.join(' ') : parts.join(', ');
  }

  String _formatCoordinates(Position position, Locale locale) {
    final latitude = position.latitude.toStringAsFixed(4);
    final longitude = position.longitude.toStringAsFixed(4);
    if (locale.languageCode == 'zh') {
      return '坐标 $latitude, $longitude';
    }
    return 'Coordinates $latitude, $longitude';
  }
}
