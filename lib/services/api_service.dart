import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../core/utils/app_snackbar.dart';
import '../core/storage_helper.dart';
import '../routes/app_pages.dart';

class ApiService extends GetxService {
  
  static const String _baseUrl = 'https://backend.ridealmobility.com'; // Replace with your actual URL
  
  // 🆕 ADD THIS GETTER - Exposes baseUrl for multipart requests
  String get baseUrl => _baseUrl;
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late http.Client _client;
  bool _isInitialized = false;

  // Initialize the service
  void _ensureInitialized() {
    if (!_isInitialized) {
      _client = http.Client();
      _isInitialized = true;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _ensureInitialized();
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }

  // Public method to refresh token
  Future<void> refreshAuthToken() async {
    // Token is handled by StorageHelper
  }

  // ✅ FIXED: Get auth headers using StorageHelper
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageHelper.getAuthToken();

    if (token == null || token.isEmpty) {
      print('⚠️ No auth token available for request');
      return {'Content-Type': 'application/json'};
    }

    print('🔑 Using token: ${token}');

    // ✅ ADD: Debug token info
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        
        final expValue = payload['exp'];
        if (expValue != null) {
          final exp = expValue is int ? expValue : (expValue is double ? expValue.toInt() : int.tryParse(expValue.toString()) ?? 0);
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final remaining = exp - now;

          print(
            '🕒 Token expires in: ${(remaining / 3600).toStringAsFixed(1)} hours',
          );
          
          if (remaining < 300) {
            // Less than 5 minutes
            print('⚠️ WARNING: Token expires soon!');
          }
        }
        
        if (payload.containsKey('role')) {
          print('🔍 Token role: ${payload['role']}');
        }
      }
    } catch (e) {
      print('⚠️ Could not decode token: $e');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Handle 401 - Token expired/invalid
  void _handle401() {
    print('❌ 401 Unauthorized - Clearing token and redirecting to login');
    StorageHelper.saveAuthToken(''); // Clear token
    Get.offAllNamed(Routes.LOGIN);
    // Get.snackbar(
    //   'Session Expired',
    //   'Please login again',
    //   snackPosition: SnackPosition.TOP,
    //   backgroundColor: Get.theme.colorScheme.error,
    //   colorText: Get.theme.colorScheme.onError,
    // );
  }

  // Handle API response
  ApiResponse _handleResponse(http.Response response) {
    try {
      print(
        '📥 API Response - Status: ${response.statusCode}, Body: ${response.body}',
      );

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        _handle401();
        return ApiResponse.error('Unauthorized - Please login again', 401);
      }

      // Handle 503 Service Unavailable
      if (response.statusCode == 503) {
        print('⚠️ Server temporarily unavailable (503)');
        return ApiResponse.error(
          'Server is temporarily unavailable. Please try again later.',
          503,
        );
      }

      // Handle empty response
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse.success({'message': 'Success'});
        } else {
          return ApiResponse.error(
            'Empty response from server',
            response.statusCode,
          );
        }
      }

      // Check if response is HTML (common for error pages)
      if (response.body.trim().startsWith('<') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        print('⚠️ Received HTML response instead of JSON');
        return ApiResponse.error(
          'Server error (${response.statusCode}). Please try again later.',
          response.statusCode,
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data);
      } else {
        final errorMessage =
            data['message'] ??
            data['msg'] ??
            data['error'] ??
            'Server error occurred';
        print(
          '❌ API Error - Status: ${response.statusCode}, Message: $errorMessage',
        );
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('❌ Response parsing error: $e, Raw body: ${response.body}');

      // If JSON parsing fails but status is successful, treat as success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success({
          'message': 'Success',
          'rawResponse': response.body,
        });
      }

      return ApiResponse.error(
        'Failed to parse response from server',
        response.statusCode,
      );
    }
  }

  // Handle exceptions
  ApiResponse _handleException(dynamic e) {
    print('❌ Exception: $e');

    String errorMessage;

    if (e is SocketException) {
      errorMessage = 'No internet connection';
    } else if (e is http.ClientException) {
      errorMessage = 'Network error occurred';
    } else if (e.toString().contains('TimeoutException')) {
      errorMessage = 'Request timeout - Please try again';
    } else if (e.toString().contains('Connection refused')) {
      errorMessage = 'Server is not responding';
    } else if (e.toString().contains('HandshakeException')) {
      errorMessage = 'SSL certificate error';
    } else {
      errorMessage = 'An unexpected error occurred: ${e.toString()}';
    }

    // Show user-friendly toast
    showErrorSnackBar(
      errorMessage,
      title: 'Network Error',
    );

    return ApiResponse.error(errorMessage);
  }

  // ✅ FIXED: GET request - async headers
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      _ensureInitialized();
      String url = '$baseUrl$endpoint';

      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url).replace(queryParameters: queryParams);
        url = uri.toString();
      }

      print('📤 GET: $url');

      // ✅ Await headers
      final headers = await _getHeaders();

      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  // ✅ FIXED: POST request - async headers
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      _ensureInitialized();

      print('📤 POST: $baseUrl$endpoint');
      if (body != null) {
        print('📤 Body: $body');
      }

      // ✅ Await headers
      final headers = await _getHeaders();

      final response = await _client
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  // ✅ FIXED: PUT request - async headers
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      _ensureInitialized();

      print('📤 PUT: $baseUrl$endpoint');

      // ✅ Await headers
      final headers = await _getHeaders();

      final response = await _client
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  // ✅ FIXED: DELETE request - async headers
  Future<ApiResponse> delete(String endpoint) async {
    try {
      _ensureInitialized();

      print('📤 DELETE: $baseUrl$endpoint');

      // ✅ Await headers
      final headers = await _getHeaders();

      final response = await _client
          .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  // ✅ FIXED: PATCH request - async headers
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      _ensureInitialized();

      print('📤 PATCH: $baseUrl$endpoint');

      // ✅ Await headers
      final headers = await _getHeaders();

      final response = await _client
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  // ✅ FIXED: Upload file - async headers
  Future<ApiResponse> uploadFile(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? additionalFields,
  }) async {
    try {
      print('📤 UPLOAD: $baseUrl$endpoint');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // ✅ Await headers
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // Multipart will set its own content-type
      request.headers.addAll(headers);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );
      print('📎 File added: ${file.path}');

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
        print('📋 Additional fields: $additionalFields');
      }

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// 🛒 Buy Subscription API
  /// Creates a subscription order with backend
  Future<ApiResponse> buySubscription({
    required String driverId,
    required String planType,
    required double amount,
  }) async {
    try {
      log('🛒 ════════════════════════════════════════════════════════');
      log('🛒           BUY SUBSCRIPTION REQUEST');
      log('🛒 ════════════════════════════════════════════════════════');
      log('👤 Driver ID: $driverId');
      log('📦 Plan Type: $planType');
      log('💰 Amount: ₹$amount');

      final requestData = {
        'driverId': driverId,
        'planType': planType,
        'amount': amount,
      };

      log('📤 Request Data: ${jsonEncode(requestData)}');

      final headers = await _getHeaders();

      final response = await http
          .post(
            Uri.parse('$baseUrl/buy-subscription'),
            headers: headers,
            body: jsonEncode(requestData),
          )
          .timeout(timeoutDuration);

      log('📥 ════════════════════════════════════════════════════════');
      log('📥           BUY SUBSCRIPTION RESPONSE');
      log('📥 ════════════════════════════════════════════════════════');
      log('📥 Status Code: ${response.statusCode}');
      log('📥 Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      log('❌ Error in buySubscription: $e');
      return _handleException(e);
    }
  }

  /// 🔍 Verify Subscription Payment API
  /// Verifies payment with backend after Razorpay success
  Future<ApiResponse> verifySubscriptionPayment({
    required String driverId,
    required String planId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      log('🔍 ════════════════════════════════════════════════════════');
      log('🔍           PAYMENT VERIFICATION REQUEST');
      log('🔍 ════════════════════════════════════════════════════════');
      log('👤 Driver ID: $driverId');
      log('📦 Plan ID: $planId');
      log('💳 Payment ID: $razorpayPaymentId');
      log('📋 Order ID: $razorpayOrderId');
      log('🔒 Signature: $razorpaySignature');

      final requestData = {
        'driverId': driverId,
        'planId': planId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      };

      log('📤 Request Data: ${jsonEncode(requestData)}');

      final headers = await _getHeaders();

      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-subscription-payment'),
            headers: headers,
            body: jsonEncode(requestData),
          )
          .timeout(timeoutDuration);

      log('📥 ════════════════════════════════════════════════════════');
      log('📥           PAYMENT VERIFICATION RESPONSE');
      log('📥 ════════════════════════════════════════════════════════');
      log('📥 Status Code: ${response.statusCode}');
      log('📥 Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      log('❌ Error in verifySubscriptionPayment: $e');
      return _handleException(e);
    }
  }
}

// API Response model
class ApiResponse {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? message;
  final int? statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(Map<String, dynamic> data) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
      message: data['message'] ?? data['msg'],
    );
  }

  factory ApiResponse.error(String message, [int? statusCode]) {
    return ApiResponse._(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(isSuccess: $isSuccess, message: $message, statusCode: $statusCode)';
  }
}
