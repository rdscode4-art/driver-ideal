/// Typed API response wrapper for clean architecture
///
/// This class provides a consistent way to handle API responses across the app.
/// It includes success status, typed data, error messages, HTTP status codes,
/// and authentication status for proper error handling.
class ApiResult<T> {
  /// Indicates if the API call was successful
  final bool success;

  /// The typed response data (null if error occurred)
  final T? data;

  /// Error or success message from the API
  final String? message;

  /// HTTP status code from the response
  final int statusCode;

  /// Indicates if the request failed due to unauthorized access (401)
  final bool unauthorized;

  /// Response time in milliseconds for performance monitoring
  final int? responseTimeMs;

  const ApiResult({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
    this.unauthorized = false,
    this.responseTimeMs,
  });

  /// Factory constructor for successful API responses
  factory ApiResult.success({
    required T data,
    String? message,
    int statusCode = 200,
    int? responseTimeMs,
  }) {
    return ApiResult<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      unauthorized: false,
      responseTimeMs: responseTimeMs,
    );
  }

  /// Factory constructor for failed API responses
  factory ApiResult.error({
    required String message,
    int statusCode = 500,
    bool unauthorized = false,
    int? responseTimeMs,
  }) {
    return ApiResult<T>(
      success: false,
      data: null,
      message: message,
      statusCode: statusCode,
      unauthorized: unauthorized,
      responseTimeMs: responseTimeMs,
    );
  }

  /// Factory constructor for unauthorized responses (401)
  factory ApiResult.unauthorized({
    String message = 'Authentication failed. Please login again.',
    int? responseTimeMs,
  }) {
    return ApiResult<T>(
      success: false,
      data: null,
      message: message,
      statusCode: 401,
      unauthorized: true,
      responseTimeMs: responseTimeMs,
    );
  }

  /// Factory constructor for network errors
  factory ApiResult.networkError({
    String message = 'No internet connection. Please check your network.',
    int? responseTimeMs,
  }) {
    return ApiResult<T>(
      success: false,
      data: null,
      message: message,
      statusCode: 0,
      unauthorized: false,
      responseTimeMs: responseTimeMs,
    );
  }

  /// Check if the result has data
  bool get hasData => data != null;

  /// Check if the result is a network error
  bool get isNetworkError => statusCode == 0;

  /// Check if the result is a server error (5xx)
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Check if the result is a client error (4xx)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  @override
  String toString() {
    return 'ApiResult<$T>(success: $success, statusCode: $statusCode, '
        'message: $message, hasData: $hasData, unauthorized: $unauthorized)';
  }

  /// Create a copy of this result with updated values
  ApiResult<T> copyWith({
    bool? success,
    T? data,
    String? message,
    int? statusCode,
    bool? unauthorized,
    int? responseTimeMs,
  }) {
    return ApiResult<T>(
      success: success ?? this.success,
      data: data ?? this.data,
      message: message ?? this.message,
      statusCode: statusCode ?? this.statusCode,
      unauthorized: unauthorized ?? this.unauthorized,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    );
  }
}
