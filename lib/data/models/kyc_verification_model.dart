import 'package:flutter/material.dart';

// New response model matching your API format
class KycVerificationStatusResponse {
  final bool success;
  final String status; // 👈 THIS IS THE REAL STATUS
  final UploadedDocs? uploaded;
  final KycVerification? verification;

  KycVerificationStatusResponse({
    required this.success,
    required this.status,
    this.uploaded,
    this.verification,
  });

  factory KycVerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    return KycVerificationStatusResponse(
      success: json['success'] ?? false,
      status: json['status'] ?? 'unknown',
      uploaded: json['uploaded'] != null
          ? UploadedDocs.fromJson(json['uploaded'])
          : null,
      verification: json['verification'] != null
          ? KycVerification.fromJson(json['verification'])
          : null,
    );
  }
}
class UploadedDocs {
  final bool aadhaar;
  final bool license;
  final bool rc;
  final bool insurance;

  UploadedDocs({
    required this.aadhaar,
    required this.license,
    required this.rc,
    required this.insurance,
  });

  factory UploadedDocs.fromJson(Map<String, dynamic> json) {
    return UploadedDocs(
      aadhaar: json['aadhaar'] ?? false,
      license: json['license'] ?? false,
      rc: json['rc'] ?? false,
      insurance: json['insurance'] ?? false,
    );
  }
}

// Legacy response for backward compatibility
class KycVerificationResponse {
  final bool success;
  final String message;
  final KycVerification? verification;

  KycVerificationResponse({
    required this.success,
    required this.message,
    this.verification,
  });

  factory KycVerificationResponse.fromJson(Map<String, dynamic> json) {
    return KycVerificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      verification: json['verification'] != null
          ? KycVerification.fromJson(json['verification'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'verification': verification?.toJson(),
    };
  }
}

class KycVerification {
  final String id;
  final String aadhaarNumber;
  final String aadhaarPic;
  final String drivingLicenseNumber;
  final String drivingLicensePic;
  final String vehicleNumber;
  final String vehicleType;
  final String vehicleImage;
  final String vehicleName;
  final String vehicleRC;
  final String vehicleInsurance;
  final String status;
  final DateTime submittedAt;

  KycVerification({
    required this.id,
    required this.aadhaarNumber,
    required this.aadhaarPic,
    required this.drivingLicenseNumber,
    required this.drivingLicensePic,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleImage,
    required this.vehicleName,
    required this.vehicleRC,
    required this.vehicleInsurance,
    required this.status,
    required this.submittedAt,
  });

  factory KycVerification.fromJson(Map<String, dynamic> json) {
    return KycVerification(
      id: json['_id'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      aadhaarPic: json['aadhaarPic'] ?? '',
      drivingLicenseNumber: json['drivingLicenseNumber'] ?? '',
      drivingLicensePic: json['drivingLicensePic'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleImage: json['vehicleImage'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      vehicleRC: json['vehicleRC'] ?? '',
      vehicleInsurance: json['vehicleInsurance'] ?? '',
      status: json['status'] ?? 'pending',
      submittedAt: DateTime.parse(json['submittedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
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
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  // Helper methods for UI display
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'incomplete':
        return 'InComplete';
      case 'pending':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Get masked Aadhaar number (show only last 4 digits)
  String get maskedAadhaarNumber {
    if (aadhaarNumber.length >= 4) {
      return 'XXXX XXXX ${aadhaarNumber.substring(aadhaarNumber.length - 4)}';
    }
    return aadhaarNumber;
  }

  // Get full image URLs from your backend
  String getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return 'https://backend.ridealmobility.com/$imagePath';
  }

  String get fullAadhaarPicUrl => getFullImageUrl(aadhaarPic);
  String get fullDrivingLicensePicUrl => getFullImageUrl(drivingLicensePic);
  String get fullVehicleImageUrl => getFullImageUrl(vehicleImage);
  String get fullVehicleRCUrl => getFullImageUrl(vehicleRC);
  String get fullVehicleInsuranceUrl => getFullImageUrl(vehicleInsurance);
}
