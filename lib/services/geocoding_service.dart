import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class GeocodingService {
  // Using a free geocoding service - you can replace with Google Maps API if needed
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Geocode an address to get coordinates
  static Future<Map<String, double?>> getCoordinatesFromAddress(String address) async {
    if (address.isEmpty) {
      return {'lat': null, 'lng': null};
    }

    try {
      log('🔍 Geocoding address: $address');

      // Clean the address for better geocoding
      final cleanAddress = _cleanAddress(address);

      final url = '$_baseUrl/search?q=${Uri.encodeComponent(cleanAddress)}&format=json&limit=1&countrycodes=in';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'RiDeal-Driver-App/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);

        if (results.isNotEmpty) {
          final result = results[0];
          final lat = double.tryParse(result['lat']?.toString() ?? '');
          final lng = double.tryParse(result['lon']?.toString() ?? '');

          log('✅ Geocoding successful: ($lat, $lng) for "$address"');
          return {'lat': lat, 'lng': lng};
        }
      }

      log('❌ No geocoding results found for: $address');
      return {'lat': null, 'lng': null};

    } catch (e) {
      log('❌ Geocoding error for "$address": $e');
      return {'lat': null, 'lng': null};
    }
  }

  /// Extract coordinates if they're embedded in the address string
  static Map<String, double?> extractCoordinatesFromString(String locationString) {
    try {
      log('���� Extracting coordinates from: "$locationString"');

      // Check for various coordinate formats that might come from backend:
      // "28.6139,77.2090:Address"
      // "lat:28.6139,lng:77.2090,address"
      // "28.6139, 77.2090 - Address"
      // "pickup: 28.6139,77.2090 Address"
      // "Address (28.6139, 77.2090)"
      // "28.6139|77.2090|Address"
      // "28.6139;77.2090;Address"
      // "coordinates:28.6139,77.2090"
      // "loc:28.6139,77.2090"
      // "position:28.6139,77.2090"
      // "geo:28.6139,77.2090"
      // "[28.6139,77.2090]Address"
      // "{lat:28.6139,lng:77.2090}"

      // Pattern 1: JSON-like format {lat:28.6139,lng:77.2090}
      RegExp jsonPattern = RegExp(r'\{["\x27]?lat["\x27]?\s*:\s*(-?\d+\.?\d*)[,\s]+["\x27]?lng["\x27]?\s*:\s*(-?\d+\.?\d*)\}', caseSensitive: false);

      // Pattern 2: Explicit lat/lng labels with various separators
      RegExp labelPattern = RegExp(r'lat[:\s=]*(-?\d+\.?\d*)[,\s;|]+lng[:\s=]*(-?\d+\.?\d*)', caseSensitive: false);

      // Pattern 3: Coordinate prefixes (coordinates:, loc:, geo:, position:)
      RegExp prefixPattern = RegExp(r'(?:coordinates?|loc|geo|position)[:\s=]*(-?\d+\.?\d*)[,\s;|]\s*(-?\d+\.?\d*)', caseSensitive: false);

      // Pattern 4: Square brackets format [28.6139,77.2090]
      RegExp bracketPattern = RegExp(r'\[(-?\d+\.?\d*)[,\s]\s*(-?\d+\.?\d*)\]');

      // Pattern 5: Parentheses format (28.6139, 77.2090)
      RegExp parenPattern = RegExp(r'\((-?\d+\.?\d*)[,\s]\s*(-?\d+\.?\d*)\)');

      // Pattern 6: Pipe separator 28.6139|77.2090
      RegExp pipePattern = RegExp(r'(-?\d+\.?\d*)\|(-?\d+\.?\d*)');

      // Pattern 7: Semicolon separator 28.6139;77.2090
      RegExp semicolonPattern = RegExp(r'(-?\d+\.?\d*);(-?\d+\.?\d*)');

      // Pattern 8: Colon separator at start 28.6139:77.2090
      RegExp colonPattern = RegExp(r'(-?\d+\.?\d*):(-?\d+\.?\d*)(?![:\d])');

      // Pattern 9: Standard comma format (most common) 28.6139,77.2090
      RegExp commaPattern = RegExp(r'(?:^|[^\d])(-?\d+\.?\d*)[,\s]\s*(-?\d+\.?\d*)(?![,\d])');

      // Pattern 10: Space-only separator 28.6139 77.2090
      RegExp spacePattern = RegExp(r'(?:^|[^\d])(-?\d{1,2}\.\d+)\s+(-?\d{1,3}\.\d+)(?![,\d])');

      // Apply patterns in order of specificity (most specific first)
      List<RegExp> patterns = [
        jsonPattern,
        labelPattern,
        prefixPattern,
        bracketPattern,
        parenPattern,
        pipePattern,
        semicolonPattern,
        colonPattern,
        commaPattern,
        spacePattern
      ];

      for (int i = 0; i < patterns.length; i++) {
        RegExp pattern = patterns[i];
        Match? match = pattern.firstMatch(locationString);

        if (match != null) {
          final lat = double.tryParse(match.group(1) ?? '');
          final lng = double.tryParse(match.group(2) ?? '');

          if (lat != null && lng != null &&
              lat >= -90 && lat <= 90 &&
              lng >= -180 && lng <= 180) {
            log('✅ Extracted coordinates using pattern ${i + 1}: ($lat, $lng) from "$locationString"');
            return {'lat': lat, 'lng': lng};
          }
        }
      }

      // Additional check for coordinate-like numbers even without clear separators
      // Look for sequences that look like coordinates
      RegExp anyNumberPattern = RegExp(r'(-?\d{1,2}\.\d{4,})[^\d]*(-?\d{1,3}\.\d{4,})');
      Match? anyMatch = anyNumberPattern.firstMatch(locationString);

      if (anyMatch != null) {
        final lat = double.tryParse(anyMatch.group(1) ?? '');
        final lng = double.tryParse(anyMatch.group(2) ?? '');

        if (lat != null && lng != null &&
            lat >= -90 && lat <= 90 &&
            lng >= -180 && lng <= 180) {
          log('✅ Extracted coordinates using fallback pattern: ($lat, $lng) from "$locationString"');
          return {'lat': lat, 'lng': lng};
        }
      }

      log('❌ No valid coordinates found in: "$locationString"');
      return {'lat': null, 'lng': null};
    } catch (e) {
      log('❌ Error extracting coordinates from "$locationString": $e');
      return {'lat': null, 'lng': null};
    }
  }

  /// Generate realistic coordinates for Delhi/NCR area based on address
  static Map<String, double> generateRealisticDelhiCoordinates(String address, String fallbackSeed) {
    // Delhi area bounds
    const double delhiCenterLat = 28.6139;
    const double delhiCenterLng = 77.2090;
    const double radius = 0.1; // ~11km radius

    // Use address content to determine area
    final addressLower = address.toLowerCase();

    // Known Delhi areas with approximate coordinates
    final Map<String, Map<String, double>> knownAreas = {
      'connaught': {'lat': 28.6315, 'lng': 77.2167},
      'cp': {'lat': 28.6315, 'lng': 77.2167},
      'karol bagh': {'lat': 28.6507, 'lng': 77.1901},
      'lajpat nagar': {'lat': 28.5665, 'lng': 77.2432},
      'khan market': {'lat': 28.5986, 'lng': 77.2304},
      'saket': {'lat': 28.5245, 'lng': 77.2066},
      'vasant kunj': {'lat': 28.5355, 'lng': 77.1587},
      'gurgaon': {'lat': 28.4595, 'lng': 77.0266},
      'gurugram': {'lat': 28.4595, 'lng': 77.0266},
      'noida': {'lat': 28.5355, 'lng': 77.3910},
      'dwarka': {'lat': 28.5921, 'lng': 77.0460},
      'rohini': {'lat': 28.7041, 'lng': 77.1025},
      'pitampura': {'lat': 28.6934, 'lng': 77.1314},
      'janakpuri': {'lat': 28.6219, 'lng': 77.0854},
      'laxmi nagar': {'lat': 28.6332, 'lng': 77.2772},
      'preet vihar': {'lat': 28.6329, 'lng': 77.2954},
      'mayur vihar': {'lat': 28.6103, 'lng': 77.2947},
      'vasundhara': {'lat': 28.6607, 'lng': 77.3741},
      'indirapuram': {'lat': 28.6415, 'lng': 77.3674},
      'faridabad': {'lat': 28.4089, 'lng': 77.3178},
    };

    // Check if address contains known area
    for (final area in knownAreas.keys) {
      if (addressLower.contains(area)) {
        final coords = knownAreas[area]!;
        // Add small random variation
        final hash = (address + fallbackSeed).hashCode;
        const variation = 0.002; // ~200m variation
        return {
          'lat': coords['lat']! + (variation * ((hash % 100 - 50) / 100)),
          'lng': coords['lng']! + (variation * ((hash % 100 - 50) / 100)),
        };
      }
    }

    // Fallback to random Delhi coordinates
    final hash = (address + fallbackSeed).hashCode;
    return {
      'lat': delhiCenterLat + (radius * ((hash % 100 - 50) / 100)),
      'lng': delhiCenterLng + (radius * ((hash % 100 - 50) / 100)),
    };
  }

  static String _cleanAddress(String address) {
    // Remove common prefixes/suffixes that might interfere with geocoding
    String cleaned = address
        .replaceAll(RegExp(r'^(pickup|drop|pickup:|\s*drop:|from:|to:)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // DON'T automatically add India - let the original address be geocoded as-is
    // This was causing incorrect coordinates by modifying the exact address

    return cleaned;
  }
}
