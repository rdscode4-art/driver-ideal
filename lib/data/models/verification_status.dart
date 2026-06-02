class VerificationStatus {
  final bool success;
  final String status;
  final VerificationData? verification;

  VerificationStatus({
    required this.success,
    required this.status,
    this.verification,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      success: json['success'] ?? false,
      status: json['status'] ?? '',
      verification: json['verification'] != null
          ? VerificationData.fromJson(json['verification'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'status': status,
      'verification': verification?.toJson(),
    };
  }
}

class VerificationData {
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

  VerificationData({
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

  factory VerificationData.fromJson(Map<String, dynamic> json) {
    // Handle aadhaarPic which can be a String or a List<String>
    String aadhaarPicUrl = '';
    if (json['aadhaarPic'] is List) {
      final list = json['aadhaarPic'] as List;
      if (list.isNotEmpty) {
        aadhaarPicUrl = list[0].toString();
      }
    } else {
      aadhaarPicUrl = json['aadhaarPic']?.toString() ?? '';
    }

    return VerificationData(
      id: json['_id'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      aadhaarPic: aadhaarPicUrl,
      drivingLicenseNumber: json['drivingLicenseNumber'] ?? '',
      drivingLicensePic: json['drivingLicensePic'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleImage: json['vehicleImage'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      vehicleRC: json['vehicleRC'] ?? '',
      vehicleInsurance: json['vehicleInsurance'] ?? '',
      status: json['status'] ?? '',
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
  String get maskedAadhaarNumber {
    if (aadhaarNumber.length > 4) {
      return '*' * (aadhaarNumber.length - 4) + aadhaarNumber.substring(aadhaarNumber.length - 4);
    }
    return aadhaarNumber;
  }

  String get formattedSubmissionDate {
    // Format: DD/MM/YYYY at HH:MM:SS AM/PM
    final day = submittedAt.day.toString().padLeft(2, '0');
    final month = submittedAt.month.toString().padLeft(2, '0');
    final year = submittedAt.year.toString();

    final hour = submittedAt.hour;
    final minute = submittedAt.minute.toString().padLeft(2, '0');
    final second = submittedAt.second.toString().padLeft(2, '0');

    // Convert to 12-hour format with AM/PM
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm = hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year at ${displayHour.toString().padLeft(2, '0')}:$minute:$second $amPm';
  }

  // Additional method for exact timestamp
  String get exactSubmissionDateTime {
    // Format: Monday, 06 Sep 2025 at 02:30:45 PM
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final weekday = weekdays[submittedAt.weekday - 1];
    final day = submittedAt.day.toString().padLeft(2, '0');
    final month = months[submittedAt.month - 1];
    final year = submittedAt.year.toString();

    final hour = submittedAt.hour;
    final minute = submittedAt.minute.toString().padLeft(2, '0');
    final second = submittedAt.second.toString().padLeft(2, '0');

    // Convert to 12-hour format with AM/PM
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm = hour >= 12 ? 'PM' : 'AM';

    return '$weekday, $day $month $year at ${displayHour.toString().padLeft(2, '0')}:$minute:$second $amPm';
  }

  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
      case 'APPROVED':
        return 'Approved';
      case 'rejected':
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Unknown Status';
    }
  }
}
