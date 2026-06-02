class Ride {
  final String id;
  final String riderId;
  final String? driverId;
  final String pickupLocation;
  final String dropoffLocation;
  final String rideType;
  final double estimatedFare;
  final String status;
  final String? promoCode;
  final String feedback;
  final String? rebookedFrom;
  final String otp;
  final DateTime createdAt;
  final int? numberOfPersons;
  final DateTime? scheduledAt;
  final String? passengerName; // Add passenger name property
  final String? passengerPhone; // Add passenger phone for additional info
  final String? pickupaddress;
  final String? dropaddress;
  // Add coordinate properties for exact locations
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String? paymentStatus;
  final String? paymentMethod;

  // Multi-stop support
  final List<String>? stops;

  // Getter to check if ride is scheduled
  bool get isScheduled => scheduledAt != null;

  // Getter to check if ride has multiple stops
  bool get isMultiStop => stops != null && stops!.isNotEmpty;

  // Getter to format fare with currency symbol
  String get formattedFare => '₹${estimatedFare.toStringAsFixed(2)}';

  // Getter to display ride type in a user-friendly format
  String get rideTypeDisplayName {
    switch (rideType.toLowerCase()) {
      case 'sedan':
        return 'Sedan';
      case 'bike':
        return 'Bike';
      case 'ev':
        return 'Electric Vehicle';
      case 'suv':
        return 'SUV';
      case 'auto':
        return 'Auto Rickshaw';
      case 'hatchback':
        return 'Hatchback';
      default:
        return rideType.toUpperCase();
    }
  }

  Ride({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.rideType,
    required this.estimatedFare,
    required this.status,
    this.promoCode,
    required this.feedback,
    this.rebookedFrom,
    required this.otp,
    required this.createdAt,
    this.numberOfPersons,
    this.scheduledAt,
    this.passengerName, // Add to constructor
    this.passengerPhone, // Add to constructor
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.stops,
    this.pickupaddress,
    this.dropaddress,
    this.paymentStatus,
    this.paymentMethod,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
  // ✅ Extract rider/passenger data from nested object
  final riderData = json['rider'] is Map<String, dynamic> 
      ? json['rider'] as Map<String, dynamic> 
      : null;
  
  // ✅ Extract pickup location data
  final pickupData = json['pickupLocation'] is Map<String, dynamic>
      ? json['pickupLocation'] as Map<String, dynamic>
      : null;
  
  // ✅ Extract dropoff location data
  final dropoffData = json['dropoffLocation'] is Map<String, dynamic>
      ? json['dropoffLocation'] as Map<String, dynamic>
      : null;

  return Ride(
    id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
    riderId: json['riderId']?.toString() ?? riderData?['id']?.toString() ?? '',
    driverId: json['driverId']?.toString(),
    
    // ✅ Handle both nested object and direct string formats
    pickupLocation: pickupData != null 
        ? (pickupData['address']?.toString() ?? '')
        : (json['pickupLocation']?.toString() ?? ''),
    
    dropoffLocation: dropoffData != null
        ? (dropoffData['address']?.toString() ?? '')
        : (json['dropoffLocation']?.toString() ?? ''),
    
    dropaddress: dropoffData?['address']?.toString() ?? 
                 json['dropoffLocation']?['address']?.toString() ?? 
                 json['dropoffLocation']?.toString() ?? '',
    
    pickupaddress: pickupData?['address']?.toString() ?? 
                   json['pickupLocation']?['address']?.toString() ??
                   json['pickupLocation']?.toString() ?? '',
    
    rideType: json['rideType']?.toString() ?? 
              json['vehicleType']?.toString() ?? 
              json['vehicle_type']?.toString() ?? '',
    estimatedFare: (json['estimatedFare'] as num?)?.toDouble() ?? 0.0,
    status: json['status']?.toString() ?? '',
    promoCode: json['promoCode']?.toString(),
    feedback: json['feedback']?.toString() ?? '',
    rebookedFrom: json['rebookedFrom']?.toString(),
    otp: json['otp']?.toString() ?? '',
    
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'].toString())
        : DateTime.now(),
    
    numberOfPersons: json['numberOfPersons'] as int?,
    
    scheduledAt: json['scheduledAt'] != null
        ? DateTime.parse(json['scheduledAt'].toString())
        : null,
    
    // ✅ FIXED: Extract passenger name from nested rider object
    passengerName: riderData?['name']?.toString() ??
                   json['passengerName']?.toString() ??
                   json['passenger_name']?.toString() ??
                   json['riderName']?.toString() ??
                   json['rider_name']?.toString() ??
                   json['userName']?.toString() ??
                   json['customerName']?.toString(),
    
    // ✅ FIXED: Extract passenger phone from nested rider object
    passengerPhone: riderData?['phone']?.toString() ??
                    json['passengerPhone']?.toString() ??
                    json['passenger_phone']?.toString() ??
                    json['riderPhone']?.toString() ??
                    json['rider_phone']?.toString() ??
                    json['passengerMobile']?.toString() ??
                    json['userPhone']?.toString() ??
                    json['customerPhone']?.toString(),
    
    // ✅ FIXED: Parse coordinates from nested location objects
    pickupLatitude: pickupData?['lat'] ?? 
                    pickupData?['latitude'] ?? 
                    _parseOriginLatitude(json),
    
    pickupLongitude: pickupData?['lng'] ?? 
                     pickupData?['lon'] ?? 
                     pickupData?['longitude'] ?? 
                     _parseOriginLongitude(json),
    
    dropoffLatitude: dropoffData?['lat'] ?? 
                     dropoffData?['latitude'] ?? 
                     _parseDestinationLatitude(json),
    
    dropoffLongitude: dropoffData?['lng'] ?? 
                      dropoffData?['lon'] ?? 
                      dropoffData?['longitude'] ?? 
                      _parseDestinationLongitude(json),
    
    // Parse multi-stop information
    stops: json['stops'] != null && json['stops'] is List
        ? List<String>.from(json['stops'].map((stop) => stop.toString()))
        : null,

    paymentStatus: json['paymentStatus']?.toString() ?? json['payment_status']?.toString(),
    paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString(),
  );
}
  // Parse ORIGIN (pickup) latitude from API response - will be shown as GREEN marker
  static double? _parseOriginLatitude(Map<String, dynamic> json) {
    // Try multiple possible field names for origin/pickup latitude
    final possibleFields = [
      'pickupLatitude',
      'pickup_latitude',
      'originLatitude',
      'origin_latitude',
      'pickupLat',
      'pickup_lat',
      'originLat',
      'origin_lat',
      'fromLat',
      'from_lat',
    ];

    for (String field in possibleFields) {
      if (json.containsKey(field)) {
        final coord = _parseCoordinate(json[field]);
        if (coord != null && _isValidCoordinate(coord, 0)) {
          print('✅ Found origin latitude in field "$field": $coord');
          return coord;
        }
      }
    }

    // Try nested objects
    if (json['pickup'] != null && json['pickup'] is Map) {
      final pickup = json['pickup'] as Map<String, dynamic>;
      for (String coordType in ['latitude', 'lat', 'y']) {
        final coord = _parseCoordinate(pickup[coordType]);
        if (coord != null && _isValidCoordinate(coord, 0)) {
          print('✅ Found origin latitude in pickup.$coordType: $coord');
          return coord;
        }
      }
    }

    // Try origin object
    if (json['origin'] != null && json['origin'] is Map) {
      final origin = json['origin'] as Map<String, dynamic>;
      for (String coordType in ['latitude', 'lat', 'y']) {
        final coord = _parseCoordinate(origin[coordType]);
        if (coord != null && _isValidCoordinate(coord, 0)) {
          print('✅ Found origin latitude in origin.$coordType: $coord');
          return coord;
        }
      }
    }

    // Try coordinates array format [lng, lat] (GeoJSON)
    if (json['pickupCoordinates'] != null &&
        json['pickupCoordinates'] is List) {
      final coords = json['pickupCoordinates'] as List;
      if (coords.length >= 2) {
        final lat = _parseCoordinate(coords[1]); // GeoJSON format: [lng, lat]
        if (lat != null && _isValidCoordinate(lat, 0)) {
          print('✅ Found origin latitude in pickupCoordinates array: $lat');
          return lat;
        }
      }
    }

    // Extract from pickup location string as fallback
    final extracted = _extractCoordinateFromLocation(
      json['pickupLocation']?.toString(),
      true,
    );
    if (extracted != null) {
      print(
        '✅ Extracted origin latitude from pickup location string: $extracted',
      );
      return extracted;
    }

    print('❌ Could not find origin latitude in API response');
    return null;
  }

  // Parse ORIGIN (pickup) longitude from API response - will be shown as GREEN marker
  static double? _parseOriginLongitude(Map<String, dynamic> json) {
    // Try multiple possible field names for origin/pickup longitude
    final possibleFields = [
      'pickupLongitude',
      'pickup_longitude',
      'originLongitude',
      'origin_longitude',
      'pickupLng',
      'pickup_lng',
      'originLng',
      'origin_lng',
      'pickupLon',
      'pickup_lon',
      'fromLng',
      'from_lng',
      'fromLon',
      'from_lon',
    ];

    for (String field in possibleFields) {
      if (json.containsKey(field)) {
        final coord = _parseCoordinate(json[field]);
        if (coord != null && _isValidCoordinate(0, coord)) {
          print('✅ Found origin longitude in field "$field": $coord');
          return coord;
        }
      }
    }

    // Try nested objects
    if (json['pickup'] != null && json['pickup'] is Map) {
      final pickup = json['pickup'] as Map<String, dynamic>;
      for (String coordType in ['longitude', 'lng', 'lon', 'x']) {
        final coord = _parseCoordinate(pickup[coordType]);
        if (coord != null && _isValidCoordinate(0, coord)) {
          print('✅ Found origin longitude in pickup.$coordType: $coord');
          return coord;
        }
      }
    }

    // Try origin object
    if (json['origin'] != null && json['origin'] is Map) {
      final origin = json['origin'] as Map<String, dynamic>;
      for (String coordType in ['longitude', 'lng', 'lon', 'x']) {
        final coord = _parseCoordinate(origin[coordType]);
        if (coord != null && _isValidCoordinate(0, coord)) {
          print('✅ Found origin longitude in origin.$coordType: $coord');
          return coord;
        }
      }
    }

    // Try coordinates array format [lng, lat] (GeoJSON)
    if (json['pickupCoordinates'] != null &&
        json['pickupCoordinates'] is List) {
      final coords = json['pickupCoordinates'] as List;
      if (coords.length >= 2) {
        final lng = _parseCoordinate(coords[0]); // GeoJSON format: [lng, lat]
        if (lng != null && _isValidCoordinate(0, lng)) {
          print('✅ Found origin longitude in pickupCoordinates array: $lng');
          return lng;
        }
      }
    }

    // Extract from pickup location string as fallback
    final extracted = _extractCoordinateFromLocation(
      json['pickupLocation']?.toString(),
      false,
    );
    if (extracted != null) {
      print(
        '✅ Extracted origin longitude from pickup location string: $extracted',
      );
      return extracted;
    }

    print('❌ Could not find origin longitude in API response');
    return null;
  }

  // Parse DESTINATION (dropoff) latitude from API response - will be shown as RED marker
  static double? _parseDestinationLatitude(Map<String, dynamic> json) {
    // Try multiple possible field names for destination/dropoff latitude
    final possibleFields = [
      'dropoffLatitude',
      'dropoff_latitude',
      'destinationLatitude',
      'destination_latitude',
      'dropoffLat',
      'dropoff_lat',
      'destinationLat',
      'destination_lat',
      'toLat',
      'to_lat',
    ];

    for (String field in possibleFields) {
      if (json.containsKey(field)) {
        final coord = _parseCoordinate(json[field]);
        if (coord != null && _isValidCoordinate(coord, 0)) {
          print('✅ Found destination latitude in field "$field": $coord');
          return coord;
        }
      }
    }

    // Try nested objects
    if (json['dropoff'] != null && json['dropoff'] is Map) {
      final dropoff = json['dropoff'] as Map<String, dynamic>;
      for (String coordType in ['latitude', 'lat', 'y']) {
        final coord = _parseCoordinate(dropoff[coordType]);
        if (coord != null && _isValidCoordinate(coord, 0)) {
          print('✅ Found destination latitude in dropoff.$coordType: $coord');
          return coord;
        }
      }
    }

    // Try destination object
    if (json['destination'] != null && json['destination'] is Map) {
      final destination = json['destination'] as Map<String, dynamic>;
      for (String coordType in ['latitude', 'lat', 'y']) {
        final coord = _parseCoordinate(destination[coordType]);
        if (coord != null && _isValidCoordinate(coord, 0)) {
          print(
            '✅ Found destination latitude in destination.$coordType: $coord',
          );
          return coord;
        }
      }
    }

    // Try coordinates array format [lng, lat] (GeoJSON)
    if (json['dropoffCoordinates'] != null &&
        json['dropoffCoordinates'] is List) {
      final coords = json['dropoffCoordinates'] as List;
      if (coords.length >= 2) {
        final lat = _parseCoordinate(coords[1]); // GeoJSON format: [lng, lat]
        if (lat != null && _isValidCoordinate(lat, 0)) {
          print(
            '✅ Found destination latitude in dropoffCoordinates array: $lat',
          );
          return lat;
        }
      }
    }

    // Extract from dropoff location string as fallback
    final extracted = _extractCoordinateFromLocation(
      json['dropoffLocation']?.toString(),
      true,
    );
    if (extracted != null) {
      print(
        '✅ Extracted destination latitude from dropoff location string: $extracted',
      );
      return extracted;
    }

    print('❌ Could not find destination latitude in API response');
    return null;
  }

  // Parse DESTINATION (dropoff) longitude from API response - will be shown as RED marker
  static double? _parseDestinationLongitude(Map<String, dynamic> json) {
    // Try multiple possible field names for destination/dropoff longitude
    final possibleFields = [
      'dropoffLongitude',
      'dropoff_longitude',
      'destinationLongitude',
      'destination_longitude',
      'dropoffLng',
      'dropoff_lng',
      'destinationLng',
      'destination_lng',
      'dropoffLon',
      'dropoff_lon',
      'toLng',
      'to_lng',
      'toLon',
      'to_lon',
    ];

    for (String field in possibleFields) {
      if (json.containsKey(field)) {
        final coord = _parseCoordinate(json[field]);
        if (coord != null && _isValidCoordinate(0, coord)) {
          print('✅ Found destination longitude in field "$field": $coord');
          return coord;
        }
      }
    }

    // Try nested objects
    if (json['dropoff'] != null && json['dropoff'] is Map) {
      final dropoff = json['dropoff'] as Map<String, dynamic>;
      for (String coordType in ['longitude', 'lng', 'lon', 'x']) {
        final coord = _parseCoordinate(dropoff[coordType]);
        if (coord != null && _isValidCoordinate(0, coord)) {
          print('✅ Found destination longitude in dropoff.$coordType: $coord');
          return coord;
        }
      }
    }

    // Try destination object
    if (json['destination'] != null && json['destination'] is Map) {
      final destination = json['destination'] as Map<String, dynamic>;
      for (String coordType in ['longitude', 'lng', 'lon', 'x']) {
        final coord = _parseCoordinate(destination[coordType]);
        if (coord != null && _isValidCoordinate(0, coord)) {
          print(
            '✅ Found destination longitude in destination.$coordType: $coord',
          );
          return coord;
        }
      }
    }

    // Try coordinates array format [lng, lat] (GeoJSON)
    if (json['dropoffCoordinates'] != null &&
        json['dropoffCoordinates'] is List) {
      final coords = json['dropoffCoordinates'] as List;
      if (coords.length >= 2) {
        final lng = _parseCoordinate(coords[0]); // GeoJSON format: [lng, lat]
        if (lng != null && _isValidCoordinate(0, lng)) {
          print(
            '✅ Found destination longitude in dropoffCoordinates array: $lng',
          );
          return lng;
        }
      }
    }

    // Extract from dropoff location string as fallback
    final extracted = _extractCoordinateFromLocation(
      json['dropoffLocation']?.toString(),
      false,
    );
    if (extracted != null) {
      print(
        '✅ Extracted destination longitude from dropoff location string: $extracted',
      );
      return extracted;
    }

    print('❌ Could not find destination longitude in API response');
    return null;
  }

  // Enhanced coordinate parsing method that handles multiple API response formats
  static double? _parseCoordinateFromAPI(
    Map<String, dynamic> json,
    String locationType,
    String coordType,
  ) {
    try {
      // Try direct field access (pickupLatitude, dropoffLongitude, etc.)
      final directField =
          '$locationType${coordType.substring(0, 1).toUpperCase()}${coordType.substring(1)}';
      if (json.containsKey(directField)) {
        return _parseCoordinate(json[directField]);
      }

      // Try nested object access (pickup.latitude, dropoff.longitude, etc.)
      if (json.containsKey(locationType) && json[locationType] is Map) {
        final locationObj = json[locationType] as Map<String, dynamic>;
        if (locationObj.containsKey(coordType)) {
          return _parseCoordinate(locationObj[coordType]);
        }
      }

      // Try array format [pickup: {lat: x, lng: y}]
      if (json.containsKey('locations') && json['locations'] is List) {
        final locations = json['locations'] as List;
        for (final loc in locations) {
          if (loc is Map && loc['type'] == locationType) {
            return _parseCoordinate(loc[coordType]);
          }
        }
      }

      // Try coordinates array format
      if (json.containsKey('${locationType}Coordinates') &&
          json['${locationType}Coordinates'] is List) {
        final coords = json['${locationType}Coordinates'] as List;
        if (coords.length >= 2) {
          // GeoJSON format: [longitude, latitude]
          return coordType.contains('lat')
              ? _parseCoordinate(coords[1])
              : _parseCoordinate(coords[0]);
        }
      }

      return null;
    } catch (e) {
      print('Error parsing coordinate $locationType.$coordType: $e');
      return null;
    }
  }

  // Extract coordinates from location string (e.g., "28.6139,77.2090:Address")
  static double? _extractCoordinateFromLocation(
    String? locationString,
    bool isLatitude,
  ) {
    if (locationString == null || locationString.isEmpty) return null;

    try {
      // Pattern for coordinates at the beginning: "28.6139,77.2090:Address" or "28.6139,77.2090 Address"
      final coordPattern = RegExp(
        r'^(-?\d+\.?\d*)[,\s]\s*(-?\d+\.?\d*)(?:[:\s\-]|$)',
      );
      final match = coordPattern.firstMatch(locationString);

      if (match != null) {
        final lat = double.tryParse(match.group(1) ?? '');
        final lng = double.tryParse(match.group(2) ?? '');

        if (lat != null && lng != null && _isValidCoordinate(lat, lng)) {
          return isLatitude ? lat : lng;
        }
      }

      // Pattern for coordinates in parentheses: "Address (28.6139, 77.2090)"
      final parenPattern = RegExp(r'\((-?\d+\.?\d*)[,\s]\s*(-?\d+\.?\d*)\)');
      final parenMatch = parenPattern.firstMatch(locationString);

      if (parenMatch != null) {
        final lat = double.tryParse(parenMatch.group(1) ?? '');
        final lng = double.tryParse(parenMatch.group(2) ?? '');

        if (lat != null && lng != null && _isValidCoordinate(lat, lng)) {
          return isLatitude ? lat : lng;
        }
      }

      return null;
    } catch (e) {
      print('Error extracting coordinate from location string: $e');
      return null;
    }
  }

  // Helper method to safely parse coordinate values with enhanced validation
  static double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    try {
      double? coord;

      if (value is double) {
        coord = value;
      } else if (value is int) {
        coord = value.toDouble();
      } else if (value is String) {
        coord = double.tryParse(value);
      }

      // Validate coordinate is within realistic bounds
      if (coord != null && _isValidCoordinate(coord, coord)) {
        return coord;
      }

      return null;
    } catch (e) {
      print('Error parsing coordinate value: $e');
      return null;
    }
  }

  // Validate coordinates are within realistic bounds
  static bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        lat != 0.0 &&
        lng != 0.0; // Exclude default 0,0 coordinates
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'riderId': riderId,
      'driverId': driverId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'rideType': rideType,
      'estimatedFare': estimatedFare,
      'status': status,
      'promoCode': promoCode,
      'feedback': feedback,
      'rebookedFrom': rebookedFrom,
      'otp': otp,
      'createdAt': createdAt.toIso8601String(),
      'numberOfPersons': numberOfPersons,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'stops': stops,
    };
  }

  @override
  String toString() {
    return 'Ride(id: $id, pickup: $pickupLocation ($pickupLatitude, $pickupLongitude), dropoff: $dropoffLocation ($dropoffLatitude, $dropoffLongitude), fare: $estimatedFare, status: $status)';
  }
}
