class DriverProfile {
  final String id;
  final String phone;
  final String name;
  final bool isVerified;
  final DateTime createdAt;
  final bool isAvailable;
  final String? ownerId;
  final DriverLocation location;
  final String? ridealid;
  final String? profileImage; // 🆕 Added profile image field

  // New fields
  final double earning;
  final double wallet;
  final String? referralCode;
  final String? referredBy;
  final DriverVerification? verification;

  DriverProfile({
    required this.id,
    required this.phone,
    required this.name,
    required this.isVerified,
    required this.createdAt,
    required this.isAvailable,
    this.ownerId,
    required this.location,
    this.earning = 0.0,
    this.wallet = 0.0,
    this.referralCode,
    this.referredBy,
    this.verification,
    this.ridealid,
    this.profileImage, // 🆕 Added to constructor
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      ridealid: _safeString(json['ridealId'] ?? json['rideal_id'] ?? json['ridealid'] ?? json['id']),
      id: _safeString(json['_id'] ?? json['id']) ?? '',
      phone: _safeString(json['phone'] ?? json['phoneNumber']) ?? '',
      name: _safeString(json['name'] ?? json['displayName'] ?? json['full_name']) ?? '',
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? false,
      ownerId: _safeString(json['ownerId'] ?? json['owner_id']),
      location: DriverLocation.fromJson(json['location'] ?? {}),
      earning: (json['earning'] ?? json['earnings'] ?? 0).toDouble(),
      wallet: (json['wallet'] ?? json['wallet_balance'] ?? 0).toDouble(),
      referralCode: _safeString(json['referralCode'] ?? json['referral_code']),
      referredBy: _safeString(json['referredBy'] ?? json['referred_by']),
      verification: json['verification'] != null
          ? DriverVerification.fromJson(json['verification'])
          : null,
      profileImage: _safeString(json['profileImage'] ?? json['profile_image'] ?? json['profilePic'] ?? json['avatar']),
    );
  }

  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List && value.isNotEmpty) return value.first.toString();
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    try {
      if (dateValue is String) return DateTime.parse(dateValue);
      if (dateValue is DateTime) return dateValue;
      return DateTime.now();
    } catch (e) {
      print('❌ Error parsing date: $dateValue');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'phone': phone,
      'name': name,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'isAvailable': isAvailable,
      'ownerId': ownerId,
      'location': location.toJson(),
      'earning': earning,
      'wallet': wallet,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'verification': verification?.toJson(),
      'profileImage': profileImage, // 🆕 Include in JSON
    };
  }

  // Helper getters
  String get displayName => name.isNotEmpty ? name : 'Driver';
  String get formattedPhone => phone.isNotEmpty ? phone : 'Not provided';
  String get verificationStatus => isVerified ? 'Verified' : 'Pending';
  String get availabilityStatus => isAvailable ? 'Available' : 'Offline';
  String get memberSince => '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  
  // 🆕 Helper getter for full profile image URL
  String get fullProfileImageUrl {
    if (profileImage == null || profileImage!.isEmpty) return '';
    if (profileImage!.startsWith('http')) return profileImage!;
    return 'https://backend.ridealmobility.com/$profileImage';
  }

  @override
  String toString() {
    return 'DriverProfile(id: $id, name: $name, phone: $phone, isVerified: $isVerified, earning: $earning)';
  }
}

class DriverLocation {
  final double lat;
  final double lng;

  DriverLocation({
    required this.lat,
    required this.lng,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };

  bool get hasLocation => lat != 0.0 || lng != 0.0;
  String get coordinates => '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  @override
  String toString() => 'DriverLocation(lat: $lat, lng: $lng)';
}

class DriverVerification {
  final String? aadhaarNumber;
  final String? aadhaarPic;
  final String? drivingLicenseNumber;
  final String? drivingLicensePic;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? vehicleImage;
  final String? vehicleName;
  final String? vehicleRC;
  final String? vehicleInsurance;
  final String? status;
  final String? id;
  final DateTime? submittedAt;

  DriverVerification({
    this.aadhaarNumber,
    this.aadhaarPic,
    this.drivingLicenseNumber,
    this.drivingLicensePic,
    this.vehicleNumber,
    this.vehicleType,
    this.vehicleImage,
    this.vehicleName,
    this.vehicleRC,
    this.vehicleInsurance,
    this.status,
    this.id,
    this.submittedAt,
  });

  factory DriverVerification.fromJson(Map<String, dynamic> json) {
    return DriverVerification(
      aadhaarNumber: _safeString(json['aadhaarNumber']),
      aadhaarPic: _safeString(json['aadhaarPic']),
      drivingLicenseNumber: _safeString(json['drivingLicenseNumber']),
      drivingLicensePic: _safeString(json['drivingLicensePic']),
      vehicleNumber: _safeString(json['vehicleNumber']),
      vehicleType: _safeString(json['vehicleType']),
      vehicleImage: _safeString(json['vehicleImage']),
      vehicleName: _safeString(json['vehicleName']),
      vehicleRC: _safeString(json['vehicleRC']),
      vehicleInsurance: _safeString(json['vehicleInsurance']),
      status: _safeString(json['status']),
      id: _safeString(json['_id']),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
    );
  }

  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List && value.isNotEmpty) return value.first.toString();
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'aadhaarNumber': aadhaarNumber,
      'aadhaarPic': aadhaarPic,
      'drivingLicenseNumber': drivingLicenseNumber,
      'drivingLicensePic': drivingLicensePic,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'vehicleImage': vehicleImage,
      'vehicleName': vehicleName,
      'vehicleRC': vehicleRC,
      'vehicleInsurance': vehicleInsurance,
      'status': status,
      '_id': id,
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'DriverVerification(status: $status, vehicleType: $vehicleType)';
}