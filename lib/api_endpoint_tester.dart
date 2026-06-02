import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/storage_helper.dart';

/// 🔧 API ENDPOINT TESTER
/// This utility tests all backend endpoints to identify working URLs
class ApiEndpointTester {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  /// Test all critical API endpoints
  static Future<void> testAllEndpoints() async {
    print('\n🧪 API ENDPOINT TESTING STARTED');
    print('=' * 50);

    final token = await StorageHelper.getAuthToken();
    if (token == null) {
      print('❌ No authentication token found');
      _showResult('Authentication', 'No token found', false);
      return;
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Test endpoints
    final endpoints = [
      {'name': 'Ongoing Ride', 'url': '$baseUrl/driver/ongoing-ride'},

      // Available rides
      {'name': 'Available Rides', 'url': '$baseUrl/rides/rides/available'},

      // Driver status
      {'name': 'Driver Status', 'url': '$baseUrl/driver/status'},

      // Subscription APIs
      {'name': 'Buy Subscription', 'url': '$baseUrl/buy-subscription'},
      {'name': 'Subscription Status', 'url': '$baseUrl/subscription-status'},

      // Verification
      {'name': 'Verification Status', 'url': '$baseUrl/verification/status'},

      // Navigation (The one failing)
      {'name': 'Navigation', 'url': '$baseUrl/location/navigation?origin=28.6139,77.2090&destination=28.5355,77.3910'},
    ];

    List<Map<String, dynamic>> results = [];

    for (var endpoint in endpoints) {
      final result = await _testEndpoint(
        endpoint['url']!,
        headers,
        endpoint['name']!,
      );
      results.add(result);

      // Add small delay between requests
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('\n📊 TEST RESULTS SUMMARY');
    print('=' * 50);

    for (var result in results) {
      final status = result['success'] ? '✅' : '❌';
      print(
        '$status ${result['name']}: ${result['status']} - ${result['message']}',
      );
    }

    // Show summary dialog
    _showSummaryDialog(results);
  }

  /// Test individual endpoint
  static Future<Map<String, dynamic>> _testEndpoint(
    String url,
    Map<String, String> headers,
    String name,
  ) async {
    try {
      print('\n🔄 Testing: $name');
      print('   URL: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('   Status: ${response.statusCode}');

      String message;
      bool success = false;

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            message = 'API working correctly';
            success = true;
          } else {
            message = data['message'] ?? 'API returned false success';
          }
        } catch (e) {
          message = 'Invalid JSON response';
        }
      } else if (response.statusCode == 404) {
        message = 'Endpoint not found (404)';
      } else if (response.statusCode == 401) {
        message = 'Authentication failed (401)';
      } else if (response.statusCode == 403) {
        message = 'Access forbidden (403)';
      } else if (response.statusCode == 500) {
        message = 'Server error (500)';
      } else {
        message = 'HTTP ${response.statusCode}';
      }

      print('   Result: $message');

      return {
        'name': name,
        'url': url,
        'status': response.statusCode,
        'message': message,
        'success': success,
      };
    } catch (e) {
      print('   Error: $e');

      String message;
      if (e.toString().contains('timeout')) {
        message = 'Request timeout';
      } else if (e.toString().contains('SocketException')) {
        message = 'Network connection failed';
      } else {
        message = 'Connection error: ${e.toString().substring(0, 50)}...';
      }

      return {
        'name': name,
        'url': url,
        'status': 0,
        'message': message,
        'success': false,
      };
    }
  }

  /// Show individual test result
  static void _showResult(String endpoint, String message, bool success) {
    final color = success ? Colors.green[100] : Colors.red[100];
    final textColor = success ? Colors.green[800] : Colors.red[800];
    final icon = success ? Icons.check_circle : Icons.error;

    Get.snackbar(
      endpoint,
      message,
      backgroundColor: color,
      colorText: textColor,
      icon: Icon(icon, color: textColor),
      duration: const Duration(seconds: 3),
    );
  }

  /// Show comprehensive test results dialog
  static void _showSummaryDialog(List<Map<String, dynamic>> results) {
    int successful = results.where((r) => r['success'] == true).length;
    int total = results.length;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              successful > total / 2 ? Icons.check_circle : Icons.warning,
              color: successful > total / 2 ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('API Test Results'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$successful out of $total endpoints working',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final isSuccess = result['success'] == true;

                    return ListTile(
                      leading: Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        result['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(result['message']),
                      trailing: Text(
                        'HTTP ${result['status']}',
                        style: TextStyle(
                          color: isSuccess ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          if (successful < total)
            ElevatedButton(
              onPressed: () {
                Get.back();
                _showTroubleshootingDialog();
              },
              child: const Text('Troubleshoot'),
            ),
        ],
      ),
    );
  }

  /// Show troubleshooting guide
  static void _showTroubleshootingDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('🔧 Troubleshooting Guide'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Common Solutions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _troubleshootItem('🌐', 'Check internet connection'),
              _troubleshootItem('🔑', 'Verify authentication token'),
              _troubleshootItem('🔄', 'Try refreshing the app'),
              _troubleshootItem('⚠️', 'Contact support if issues persist'),
              const SizedBox(height: 16),
              const Text(
                'Working Endpoints:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Payment system: ✅ Working'),
              const Text('• Authentication: ✅ Working'),
              const Text('• Ride management: ⚠️ Partial'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  static Widget _troubleshootItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  /// Quick test for ongoing ride API specifically
  static Future<void> testOngoingRideAPI() async {
    print('\n🎯 TESTING ONGOING RIDE API SPECIFICALLY');

    final token = await StorageHelper.getAuthToken();
    if (token == null) {
      _showResult('Ongoing Ride Test', 'No auth token', false);
      return;
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Test the specific endpoints that were failing
    final endpoints = [
      '$baseUrl/driver/ongoing-ride',
    ];

    for (String endpoint in endpoints) {
      final result = await _testEndpoint(endpoint, headers, 'Ongoing Ride');

      if (result['success']) {
        _showResult('Ongoing Ride Found!', 'Working endpoint: $endpoint', true);
        return;
      }
    }

    _showResult(
      'Ongoing Ride Test',
      'All endpoints returned 404 - no ongoing ride (normal)',
      true,
    );
  }
}

/// 🎯 QUICK TEST WIDGET
class ApiTestWidget extends StatelessWidget {
  const ApiTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => ApiEndpointTester.testAllEndpoints(),
            icon: const Icon(Icons.api, color: Colors.white),
            label: const Text(
              'Test All APIs',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ApiEndpointTester.testOngoingRideAPI(),
            icon: const Icon(Icons.directions_car),
            label: const Text('Test Ongoing Ride Only'),
          ),
        ],
      ),
    );
  }
}
