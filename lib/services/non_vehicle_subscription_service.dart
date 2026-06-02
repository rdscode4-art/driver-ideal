import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/api_result.dart';
import '../core/storage_helper.dart';
import '../models/non_vehicle_order_response.dart';
import '../models/non_vehicle_verify_response.dart';
import '../models/non_vehicle_subscription_status.dart';

/// Production-ready Non-Vehicle Driver Subscription Service
///
/// This service handles all subscription-related operations for non-vehicle drivers
/// including Razorpay order creation, payment verification, and status management.
///
/// Features:
/// - Clean architecture with typed responses
/// - Unified request handling with retry mechanism
/// - Comprehensive error handling and logging
/// - Exponential backoff for network errors
/// - Automatic 401 handling and token management
class NonVehicleSubscriptionService {
  // ==================== CONSTANTS ====================

  /// Backend API base URL
  static const String _baseUrl = 'https://backend.ridealmobility.com';

  /// API endpoints for non-vehicle drivers
  static const String _buySubscriptionEndpoint =
      '/api/non-vehicle-driver/buy-subscription';
  static const String _verifyPaymentEndpoint =
      '/api/non-vehicle-driver/verify-payment';
  static const String _subscriptionStatusEndpoint =
      '/api/non-vehicle-driver/status';

  /// Request timeout configuration
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _connectionTimeout = Duration(seconds: 15);

  /// Retry configuration
  static const int _maxRetries = 3;
  static const int _baseRetryDelayMs = 1000; // 1 second

  /// Singleton instance
  static final NonVehicleSubscriptionService _instance =
      NonVehicleSubscriptionService._internal();

  /// Factory constructor returning singleton
  factory NonVehicleSubscriptionService() => _instance;

  /// Private constructor for singleton
  NonVehicleSubscriptionService._internal();

  // ==================== PUBLIC API METHODS ====================

  /// 1️⃣ CREATE RAZORPAY ORDER (Buy Subscription)
  ///
  /// Creates a new Razorpay order for subscription purchase.
  ///
  /// **Endpoint:** POST /api/non-vehicle-driver/buy-subscription
  ///
  /// **Parameters:**
  /// - [driverId]: Unique identifier for the driver
  /// - [planId]: Subscription plan ID to purchase
  /// - [amount]: Amount in smallest currency unit (paise for INR)
  ///
  /// **Returns:**
  /// - [ApiResult<NonVehicleOrderResponse>]: Order details including orderId for Razorpay
  ///
  /// **Usage:**
  /// ```dart
  /// final result = await service.createOrder(
  ///   driverId: "driver123",
  ///   planId: "plan456",
  ///   amount: 10000, // ₹100.00 in paise
  /// );
  ///
  /// if (result.success) {
  ///   final orderId = result.data!.orderId;
  ///   // Use orderId to open Razorpay checkout
  /// }
  /// ```
  Future<ApiResult<NonVehicleOrderResponse>> createOrder({
    required String driverId,
    required String planId,
    required int amount,
  }) async {
    // Input validation
    if (driverId.trim().isEmpty) {
      return ApiResult.error(
        message: 'Driver ID cannot be empty',
        statusCode: 400,
      );
    }

    if (planId.trim().isEmpty) {
      return ApiResult.error(
        message: 'Plan ID cannot be empty',
        statusCode: 400,
      );
    }

    if (amount <= 0) {
      return ApiResult.error(
        message: 'Amount must be greater than zero',
        statusCode: 400,
      );
    }

    final requestBody = {
      'driverId': driverId.trim(),
      'planId': planId.trim(),
      'amount': amount,
    };

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _sendRequest<NonVehicleOrderResponse>(
        method: 'POST',
        endpoint: _buySubscriptionEndpoint,
        body: requestBody,
        parser: (json) => NonVehicleOrderResponse.fromJson(json),
        operation: 'Create Order',
      );

      stopwatch.stop();

      if (result.success && result.data != null) {
        _logSuccess(
          'Create Order',
          stopwatch.elapsedMilliseconds,
          'Order created: ${result.data!.orderId}',
        );
      }

      return result.copyWith(responseTimeMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      _logError('Create Order', e.toString(), stopwatch.elapsedMilliseconds);

      return ApiResult.error(
        message: 'Failed to create order: $e',
        statusCode: 500,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 2️⃣ VERIFY RAZORPAY PAYMENT
  ///
  /// Verifies the Razorpay payment and activates the subscription.
  ///
  /// **Endpoint:** POST /api/non-vehicle-driver/verify-payment
  ///
  /// **Parameters:**
  /// - [driverId]: Driver who made the payment
  /// - [planId]: Plan ID that was purchased
  /// - [razorpayPaymentId]: Payment ID from Razorpay success callback
  /// - [razorpayOrderId]: Order ID from Razorpay success callback
  /// - [razorpaySignature]: Signature from Razorpay success callback
  ///
  /// **Returns:**
  /// - [ApiResult<NonVehicleVerifyResponse>]: Verification status and subscription details
  ///
  /// **Usage:**
  /// ```dart
  /// final result = await service.verifyPayment(
  ///   driverId: "driver123",
  ///   planId: "plan456",
  ///   razorpayPaymentId: "pay_xxx",
  ///   razorpayOrderId: "order_xxx",
  ///   razorpaySignature: "signature_xxx",
  /// );
  ///
  /// if (result.success) {
  ///   print("Subscription activated: ${result.data!.message}");
  /// }
  /// ```
  Future<ApiResult<NonVehicleVerifyResponse>> verifyPayment({
    required String driverId,
    required String planId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    // Input validation
    if (driverId.trim().isEmpty) {
      return ApiResult.error(
        message: 'Driver ID cannot be empty',
        statusCode: 400,
      );
    }

    if (planId.trim().isEmpty) {
      return ApiResult.error(
        message: 'Plan ID cannot be empty',
        statusCode: 400,
      );
    }

    if (razorpayPaymentId.trim().isEmpty) {
      return ApiResult.error(
        message: 'Razorpay payment ID cannot be empty',
        statusCode: 400,
      );
    }

    if (razorpayOrderId.trim().isEmpty) {
      return ApiResult.error(
        message: 'Razorpay order ID cannot be empty',
        statusCode: 400,
      );
    }

    if (razorpaySignature.trim().isEmpty) {
      return ApiResult.error(
        message: 'Razorpay signature cannot be empty',
        statusCode: 400,
      );
    }

    final requestBody = {
      'driverId': driverId.trim(),
      'planId': planId.trim(),
      'razorpay_payment_id': razorpayPaymentId.trim(),
      'razorpay_order_id': razorpayOrderId.trim(),
      'razorpay_signature': razorpaySignature.trim(),
    };

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _sendRequest<NonVehicleVerifyResponse>(
        method: 'POST',
        endpoint: _verifyPaymentEndpoint,
        body: requestBody,
        parser: (json) => NonVehicleVerifyResponse.fromJson(json),
        operation: 'Verify Payment',
      );

      stopwatch.stop();

      if (result.success && result.data != null) {
        _logSuccess(
          'Verify Payment',
          stopwatch.elapsedMilliseconds,
          'Payment verified: ${result.data!.message}',
        );
      }

      return result.copyWith(responseTimeMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      _logError('Verify Payment', e.toString(), stopwatch.elapsedMilliseconds);

      return ApiResult.error(
        message: 'Failed to verify payment: $e',
        statusCode: 500,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 3️⃣ GET SUBSCRIPTION STATUS
  ///
  /// Retrieves the current subscription status for a driver.
  ///
  /// **Endpoint:** GET /api/non-vehicle-driver/status/{driverId}
  ///
  /// **Parameters:**
  /// - [driverId]: Driver ID to check subscription status for
  ///
  /// **Returns:**
  /// - [ApiResult<NonVehicleSubscriptionStatus>]: Current subscription status
  ///
  /// **Usage:**
  /// ```dart
  /// final result = await service.getSubscriptionStatus("driver123");
  ///
  /// if (result.success) {
  ///   final status = result.data!;
  ///   if (status.subscribed) {
  ///     print("Active until: ${status.endDate}");
  ///   } else {
  ///     print("No active subscription");
  ///   }
  /// }
  /// ```
  Future<ApiResult<NonVehicleSubscriptionStatus>> getSubscriptionStatus(
    String driverId,
  ) async {
    // Input validation
    if (driverId.trim().isEmpty) {
      return ApiResult.error(
        message: 'Driver ID cannot be empty',
        statusCode: 400,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _sendRequest<NonVehicleSubscriptionStatus>(
        method: 'GET',
        endpoint: '$_subscriptionStatusEndpoint/${driverId.trim()}',
        parser: (json) => NonVehicleSubscriptionStatus.fromJson(json),
        operation: 'Get Subscription Status',
        handle404AsNoSubscription: true,
      );

      stopwatch.stop();

      if (result.success && result.data != null) {
        final status = result.data!.subscribed ? 'Active' : 'No subscription';
        _logSuccess(
          'Get Subscription Status',
          stopwatch.elapsedMilliseconds,
          'Status: $status',
        );
      }

      return result.copyWith(responseTimeMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      _logError(
        'Get Subscription Status',
        e.toString(),
        stopwatch.elapsedMilliseconds,
      );

      return ApiResult.error(
        message: 'Failed to get subscription status: $e',
        statusCode: 500,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Unified method to send HTTP requests with retry logic and error handling
  ///
  /// **Type Parameters:**
  /// - [T]: Expected response type after parsing
  ///
  /// **Parameters:**
  /// - [method]: HTTP method ('GET', 'POST', 'PUT', 'DELETE')
  /// - [endpoint]: API endpoint path (without base URL)
  /// - [body]: Request body for POST/PUT requests
  /// - [parser]: Function to parse JSON response into type T
  /// - [operation]: Human-readable operation name for logging
  /// - [handle404AsNoSubscription]: Special handling for subscription status 404
  ///
  /// **Returns:**
  /// - [ApiResult<T>]: Typed API response with success/error status
  Future<ApiResult<T>> _sendRequest<T>({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    required T Function(Map<String, dynamic>) parser,
    required String operation,
    bool handle404AsNoSubscription = false,
  }) async {
    return await _executeWithRetry<T>(
      operation: operation,
      requestFunction: () async {
        return await _performHttpRequest<T>(
          method: method,
          endpoint: endpoint,
          body: body,
          parser: parser,
          operation: operation,
          handle404AsNoSubscription: handle404AsNoSubscription,
        );
      },
    );
  }

  /// Execute HTTP request with exponential backoff retry for network errors
  ///
  /// **Retry Logic:**
  /// - Retry only on network errors (SocketException, TimeoutException)
  /// - Use exponential backoff: 1s, 2s, 4s delays
  /// - Don't retry on 4xx/5xx HTTP errors (except for network connectivity issues)
  /// - Don't retry on 401 unauthorized responses
  Future<ApiResult<T>> _executeWithRetry<T>({
    required String operation,
    required Future<ApiResult<T>> Function() requestFunction,
  }) async {
    int attempt = 0;

    while (attempt <= _maxRetries) {
      try {
        final result = await requestFunction();

        // Don't retry on successful responses
        if (result.success) {
          return result;
        }

        // Don't retry on authentication errors
        if (result.unauthorized) {
          return result;
        }

        // Don't retry on client errors (4xx) except network issues
        if (result.isClientError && !result.isNetworkError) {
          return result;
        }

        // Only retry on network errors and server errors
        if (attempt < _maxRetries &&
            (result.isNetworkError || result.isServerError)) {
          final delayMs =
              _baseRetryDelayMs * (1 << attempt); // Exponential backoff
          _logRetry(operation, attempt + 1, _maxRetries + 1, delayMs);

          await Future.delayed(Duration(milliseconds: delayMs));
          attempt++;
          continue;
        }

        return result;
      } on SocketException {
        if (attempt >= _maxRetries) {
          return ApiResult.networkError();
        }

        final delayMs = _baseRetryDelayMs * (1 << attempt);
        _logRetry(operation, attempt + 1, _maxRetries + 1, delayMs);

        await Future.delayed(Duration(milliseconds: delayMs));
        attempt++;
      } on TimeoutException {
        if (attempt >= _maxRetries) {
          return ApiResult.error(
            message: 'Request timeout after multiple attempts',
            statusCode: 0,
          );
        }

        final delayMs = _baseRetryDelayMs * (1 << attempt);
        _logRetry(operation, attempt + 1, _maxRetries + 1, delayMs);

        await Future.delayed(Duration(milliseconds: delayMs));
        attempt++;
      } catch (e) {
        return ApiResult.error(
          message: 'Unexpected error: $e',
          statusCode: 500,
        );
      }
    }

    return ApiResult.error(
      message: 'Request failed after ${_maxRetries + 1} attempts',
      statusCode: 0,
    );
  }

  /// Perform actual HTTP request
  Future<ApiResult<T>> _performHttpRequest<T>({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    required T Function(Map<String, dynamic>) parser,
    required String operation,
    bool handle404AsNoSubscription = false,
  }) async {
    final url = '$_baseUrl$endpoint';
    final headers = await _getHeaders();

    _logRequest(method, url, body);

    late final http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(Uri.parse(url), headers: headers)
              .timeout(_requestTimeout);
          break;
        case 'POST':
          response = await http
              .post(
                Uri.parse(url),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_requestTimeout);
          break;
        case 'PUT':
          response = await http
              .put(
                Uri.parse(url),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_requestTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(Uri.parse(url), headers: headers)
              .timeout(_requestTimeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } on SocketException {
      throw SocketException('No internet connection');
    } on TimeoutException {
      throw TimeoutException('Request timeout', _requestTimeout);
    } on HttpException catch (e) {
      throw HttpException('HTTP error: ${e.message}');
    }

    _logResponse(response.statusCode, response.body);

    // Handle different response scenarios
    return await _handleResponse<T>(
      response: response,
      parser: parser,
      operation: operation,
      handle404AsNoSubscription: handle404AsNoSubscription,
    );
  }

  /// Handle HTTP response and parse into typed result
  Future<ApiResult<T>> _handleResponse<T>({
    required http.Response response,
    required T Function(Map<String, dynamic>) parser,
    required String operation,
    bool handle404AsNoSubscription = false,
  }) async {
    final statusCode = response.statusCode;

    // Handle successful responses (2xx)
    if (statusCode >= 200 && statusCode < 300) {
      try {
        if (response.body.trim().isEmpty) {
          throw const FormatException('Empty response body');
        }

        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final parsedData = parser(jsonData);

        return ApiResult.success(data: parsedData, statusCode: statusCode);
      } catch (e) {
        return ApiResult.error(
          message: 'Failed to parse response: $e',
          statusCode: statusCode,
        );
      }
    }

    // Handle 404 for subscription status (special case)
    if (statusCode == 404 && handle404AsNoSubscription) {
      // Return no subscription status instead of error
      final noSubscription =
          NonVehicleSubscriptionStatus.noSubscription()
              as T; // Safe cast for subscription status

      return ApiResult.success(
        data: noSubscription,
        statusCode: statusCode,
        message: 'No active subscription found',
      );
    }

    // Handle unauthorized (401)
    if (statusCode == 401) {
      await _handleUnauthorized();

      return ApiResult.unauthorized();
    }

    // Handle other error responses
    String errorMessage = 'Request failed';

    try {
      if (response.body.trim().isNotEmpty) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorData['message']?.toString() ??
            errorData['error']?.toString() ??
            errorMessage;
      }
    } catch (e) {
      // Ignore JSON parsing errors for error responses
    }

    return ApiResult.error(message: errorMessage, statusCode: statusCode);
  }

  /// Get authorization headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageHelper.getAuthToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'RiDeal-Driver-App/1.0.0',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Handle unauthorized responses (clear token and logout)
  Future<void> _handleUnauthorized() async {
    try {
      await StorageHelper.clearAuthToken();
      _logInfo('🔐 Authentication token cleared due to 401 response');
    } catch (e) {
      _logError('Handle Unauthorized', 'Failed to clear auth token: $e');
    }
  }

  // ==================== LOGGING METHODS ====================

  /// Log HTTP request details
  void _logRequest(String method, String url, [Map<String, dynamic>? body]) {
    print('🌐 [$method] $url');
    if (body != null) {
      // Hide sensitive data in logs
      final sanitizedBody = Map<String, dynamic>.from(body);
      if (sanitizedBody.containsKey('razorpay_signature')) {
        sanitizedBody['razorpay_signature'] = '***HIDDEN***';
      }
      print('📤 Body: ${jsonEncode(sanitizedBody)}');
    }
  }

  /// Log HTTP response details
  void _logResponse(int statusCode, String body) {
    final truncatedBody = body.length > 500
        ? '${body.substring(0, 500)}...[truncated]'
        : body;

    if (statusCode >= 200 && statusCode < 300) {
      print('📥 Response [$statusCode]: $truncatedBody');
    } else {
      print('❌ Error Response [$statusCode]: $truncatedBody');
    }
  }

  /// Log successful operation
  void _logSuccess(String operation, int responseTimeMs, [String? details]) {
    final timeText = '${responseTimeMs}ms';
    if (details != null) {
      print('✅ $operation completed in $timeText - $details');
    } else {
      print('✅ $operation completed in $timeText');
    }
  }

  /// Log error operation
  void _logError(String operation, String error, [int? responseTimeMs]) {
    final timeText = responseTimeMs != null ? ' (${responseTimeMs}ms)' : '';
    print('❌ $operation failed$timeText: $error');
  }

  /// Log retry attempt
  void _logRetry(String operation, int attempt, int maxAttempts, int delayMs) {
    print(
      '🔄 $operation - Retry $attempt/$maxAttempts after ${delayMs}ms delay',
    );
  }

  /// Log general information
  void _logInfo(String message) {
    print('ℹ️ $message');
  }

  // ==================== UTILITY METHODS ====================

  /// Clear any cached data or reset service state
  void clearCache() {
    _logInfo('🧹 Service cache cleared');
    // Add any cache clearing logic here if needed in future
  }

  /// Get service health status
  Future<bool> isServiceHealthy() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/health'), headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      _logError('Health Check', e.toString());
      return false;
    }
  }

  /// Get current service configuration
  Map<String, dynamic> getServiceConfig() {
    return {
      'baseUrl': _baseUrl,
      'endpoints': {
        'buySubscription': _buySubscriptionEndpoint,
        'verifyPayment': _verifyPaymentEndpoint,
        'subscriptionStatus': _subscriptionStatusEndpoint,
      },
      'timeouts': {
        'request': _requestTimeout.inSeconds,
        'connection': _connectionTimeout.inSeconds,
      },
      'retry': {
        'maxAttempts': _maxRetries + 1,
        'baseDelayMs': _baseRetryDelayMs,
      },
    };
  }
}
