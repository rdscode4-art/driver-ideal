import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class EnhancedGeocodingService {
  // Multiple geocoding providers for better success rate
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _photonBaseUrl = 'https://photon.komoot.io';

  /// Enhanced geocoding with multiple providers and fallbacks
  static Future<Map<String, double?>> getCoordinatesFromAddress(String address) async {
    if (address.isEmpty) {
      return {'lat': null, 'lng': null};
    }

    try {
      log('🔍 Enhanced geocoding for: $address');

      // Clean the address for better geocoding
      final cleanAddress = _cleanAddress(address);

      // Special handling for Indian addresses like "A43 sector 63, noida"
      final indianOptimizedAddress = _optimizeForIndianAddress(address);

      // Try multiple geocoding strategies in order of priority
      List<Map<String, dynamic>> geocodingAttempts = [
        {'method': 'indian_optimized', 'address': indianOptimizedAddress},
        {'method': 'nominatim', 'address': cleanAddress},
        {'method': 'photon', 'address': cleanAddress},
        {'method': 'variations', 'address': address},
      ];

      // Try each geocoding method
      for (Map<String, dynamic> attempt in geocodingAttempts) {
        try {
          Map<String, double?> result = {'lat': null, 'lng': null};

          switch (attempt['method']) {
            case 'indian_optimized':
              result = await _geocodeWithNominatim(attempt['address']).timeout(const Duration(seconds: 8));
              break;
            case 'nominatim':
              result = await _geocodeWithNominatim(attempt['address']).timeout(const Duration(seconds: 8));
              break;
            case 'photon':
              result = await _geocodeWithPhoton(attempt['address']).timeout(const Duration(seconds: 8));
              break;
            case 'variations':
              result = await _geocodeWithAddressVariations(attempt['address']).timeout(const Duration(seconds: 10));
              break;
          }

          if (result['lat'] != null && result['lng'] != null) {
            log('✅ Enhanced geocoding successful via ${attempt['method']}: (${result['lat']}, ${result['lng']}) for "$address"');
            return result;
          }
        } catch (e) {
          log('⚠️ Geocoding attempt ${attempt['method']} failed: $e');
          continue;
        }
      }

      log('❌ All geocoding attempts failed for: "$address"');
      return {'lat': null, 'lng': null};

    } catch (e) {
      log('❌ Enhanced geocoding error for "$address": $e');
      return {'lat': null, 'lng': null};
    }
  }

  /// Nominatim geocoding with better parameters
  static Future<Map<String, double?>> _geocodeWithNominatim(String address) async {
    try {
      final url = '$_nominatimBaseUrl/search?'
          'q=${Uri.encodeComponent(address)}'
          '&format=json'
          '&limit=1'
          '&countrycodes=in'
          '&addressdetails=1'
          '&bounded=1'
          '&viewbox=77.0,28.0,78.0,29.0'; // Delhi NCR bounding box

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'RiDeal-Driver-App/1.0 (maps@rideal.app)',
          'Accept': 'application/json',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);

        if (results.isNotEmpty) {
          final result = results[0];
          final lat = double.tryParse(result['lat']?.toString() ?? '');
          final lng = double.tryParse(result['lon']?.toString() ?? '');

          if (_isValidIndianCoordinate(lat, lng)) {
            return {'lat': lat, 'lng': lng};
          }
        }
      }

      return {'lat': null, 'lng': null};
    } catch (e) {
      log('❌ Nominatim geocoding error: $e');
      return {'lat': null, 'lng': null};
    }
  }

  /// Photon geocoding (alternative OSM-based service)
  static Future<Map<String, double?>> _geocodeWithPhoton(String address) async {
    try {
      final url = '$_photonBaseUrl/api?'
          'q=${Uri.encodeComponent(address)}'
          '&limit=1'
          '&lang=en'
          '&bbox=77.0,28.0,78.0,29.0'; // Delhi NCR bounding box

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'RiDeal-Driver-App/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final coordinates = feature['geometry']['coordinates'];

          if (coordinates != null && coordinates.length >= 2) {
            final lng = double.tryParse(coordinates[0]?.toString() ?? '');
            final lat = double.tryParse(coordinates[1]?.toString() ?? '');

            if (_isValidIndianCoordinate(lat, lng)) {
              return {'lat': lat, 'lng': lng};
            }
          }
        }
      }

      return {'lat': null, 'lng': null};
    } catch (e) {
      log('❌ Photon geocoding error: $e');
      return {'lat': null, 'lng': null};
    }
  }

  /// Try different address variations
  static Future<Map<String, double?>> _geocodeWithAddressVariations(String originalAddress) async {
    // Create intelligent address variations
    List<String> variations = _generateAddressVariations(originalAddress);

    for (String variation in variations) {
      if (variation == originalAddress) continue;

      log('🔄 Trying variation: "$variation"');

      final result = await _geocodeWithNominatim(variation);
      if (result['lat'] != null && result['lng'] != null) {
        log('✅ Variation successful: "$variation"');
        return result;
      }

      // Respectful delay between requests
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return {'lat': null, 'lng': null};
  }

  /// Generate intelligent address variations
  static List<String> _generateAddressVariations(String address) {
    Set<String> variations = {address};

    // Basic cleaning
    String cleaned = address.trim().toLowerCase();

    // Add common location suffixes
    variations.addAll([
      '$address, India',
      '$address, Delhi',
      '$address, NCR',
      '$address, Delhi NCR',
      '$address, New Delhi',
    ]);

    // Fix common area names
    Map<String, String> replacements = {
      'noida': 'Noida, Uttar Pradesh',
      'gurgaon': 'Gurugram, Haryana',
      'gurgram': 'Gurugram, Haryana',
      'faridabad': 'Faridabad, Haryana',
      'ghaziabad': 'Ghaziabad, Uttar Pradesh',
      'sector': 'Sector',
      'block': 'Block',
      'phase': 'Phase',
    };

    replacements.forEach((from, to) {
      if (cleaned.contains(from)) {
        variations.add(address.replaceAll(RegExp(from, caseSensitive: false), to));
      }
    });

    // Remove punctuation variations
    variations.add(address.replaceAll(RegExp(r'[,.-]'), ' '));
    variations.add(address.replaceAll(RegExp(r'\s+'), ' '));

    return variations.toList();
  }

  /// Validate coordinates are within India
  static bool _isValidIndianCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;

    // India bounding box (approximate)
    return lat >= 6.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.0;
  }

  /// Clean address for better geocoding
  static String _cleanAddress(String address) {
    return address
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s,.-]'), '')
        .replaceAll(RegExp(r'^(pickup|drop|destination|from|to)[:;]?\s*', caseSensitive: false), '');
  }

  /// Optimize address specifically for Indian locations
  static String _optimizeForIndianAddress(String address) {
    String optimized = address.trim();

    // Common Indian address patterns
    Map<String, String> indiaOptimizations = {
      // Noida specific optimizations
      r'sector\s*(\d+)[,\s]*noida': 'Sector \$1, Noida, Uttar Pradesh, India',
      r'([a-z]\d+)[,\s]*sector\s*(\d+)[,\s]*noida': '\$1, Sector \$2, Noida, Uttar Pradesh, India',

      // Gurgaon/Gurugram
      r'sector\s*(\d+)[,\s]*gurg[ra]on': 'Sector \$1, Gurugram, Haryana, India',
      r'sector\s*(\d+)[,\s]*gurugram': 'Sector \$1, Gurugram, Haryana, India',

      // Delhi sectors
      r'sector\s*(\d+)[,\s]*delhi': 'Sector \$1, Delhi, India',

      // Phase patterns
      r'phase\s*(\d+)[,\s]*([a-z\s]+)': 'Phase \$1, \$2, India',

      // Block patterns
      r'block\s*([a-z])[,\s]*([a-z\s]+)': 'Block \$1, \$2, India',
    };

    // Apply optimizations
    for (String pattern in indiaOptimizations.keys) {
      RegExp regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(optimized)) {
        optimized = optimized.replaceAllMapped(regex, (match) {
          String replacement = indiaOptimizations[pattern]!;
          for (int i = 1; i <= match.groupCount; i++) {
            replacement = replacement.replaceAll('\$$i', match.group(i) ?? '');
          }
          return replacement;
        });
        log('🔧 Optimized address: "$address" → "$optimized"');
        break;
      }
    }

    // If no pattern matched, add India suffix if not present
    if (!optimized.toLowerCase().contains('india') &&
        !optimized.toLowerCase().contains('delhi') &&
        !optimized.toLowerCase().contains('uttar pradesh') &&
        !optimized.toLowerCase().contains('haryana')) {

      // Detect city and add proper state
      if (optimized.toLowerCase().contains('noida')) {
        optimized = '$optimized, Uttar Pradesh, India';
      } else if (optimized.toLowerCase().contains('gurg')) {
        optimized = '$optimized, Haryana, India';
      } else if (optimized.toLowerCase().contains('faridabad')) {
        optimized = '$optimized, Haryana, India';
      } else if (optimized.toLowerCase().contains('ghaziabad')) {
        optimized = '$optimized, Uttar Pradesh, India';
      } else {
        optimized = '$optimized, Delhi, India';
      }
    }

    return optimized;
  }
}
