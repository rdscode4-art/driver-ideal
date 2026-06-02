// Quick KYC API test
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testKycStatusAPI();
}

Future<void> testKycStatusAPI() async {
  const String baseUrl = 'https://backend.ridealmobility.com';

  // Test token from logs (replace with actual token)
  const String testToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5NGY3MDljYjllYWQ2NzhmNGExZTM4ZSIsInJvbGUiOiJkcml2ZXIiLCJpYXQiOjE3NjY4MTczODQsImV4cCI6MTc2OTQwOTM4NH0.RYh1oWBXSPH0HF64H0hIxd9h9B3wZuI442wv2suoAO0';

  print('🧪 Testing KYC Status API...');
  print('📡 Endpoint: $baseUrl/verification/status');

  try {
    final response = await http
        .get(
          Uri.parse('$baseUrl/verification/status'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 30));

    print('📨 Response Status: ${response.statusCode}');
    print('📨 Response Headers: ${response.headers}');
    print('📨 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        print('✅ JSON parsing successful');
        print('📊 Data structure: ${data.runtimeType}');
        print('📋 Data keys: ${data.keys}');

        if (data['success'] == true) {
          print('✅ API Response Success: true');
          if (data['status'] != null) {
            print('📊 Status: ${data['status']}');
          }
          if (data['verification'] != null) {
            print('📋 Verification data found');
            final verification = data['verification'];
            print('🔍 Verification status: ${verification['status']}');
          }
        }
      } catch (e) {
        print('❌ JSON parsing failed: $e');
      }
    } else {
      print('❌ API call failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('💥 Exception occurred: $e');
  }
}
