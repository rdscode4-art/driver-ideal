import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';
import '../data/models/referral_model.dart';

class NonVehicleReferralApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  Future<ReferralDashboardData?> getDriverReferrals() async {
    try {
      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        print('Error: Token not found');
        return null;
      }

      final url = Uri.parse('$baseUrl/api/non-vehicle-driver/referrals');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ReferralDashboardData.fromJson(data);
        }
      }
      print('Failed to load referrals: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error fetching referrals: $e');
      return null;
    }
  }
}
