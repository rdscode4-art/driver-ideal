import '../services/api_service.dart';

class EarningsApiService {
  static final ApiService _apiService = ApiService();

  // Get earnings summary
  static Future<ApiResponse> getEarningsSummary({
    String? period, // 'daily', 'weekly', 'monthly'
    String? fromDate,
    String? toDate,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (period != null) queryParams['period'] = period;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      return await _apiService.get('/earnings/summary', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get earnings summary: ${e.toString()}');
    }
  }

  // Get daily earnings
  static Future<ApiResponse> getDailyEarnings(String date) async {
    try {
      return await _apiService.get('/earnings/daily', queryParams: {
        'date': date,
      });
    } catch (e) {
      return ApiResponse.error('Failed to get daily earnings: ${e.toString()}');
    }
  }

  // Get weekly earnings
  static Future<ApiResponse> getWeeklyEarnings(String weekStart) async {
    try {
      return await _apiService.get('/earnings/weekly', queryParams: {
        'week_start': weekStart,
      });
    } catch (e) {
      return ApiResponse.error('Failed to get weekly earnings: ${e.toString()}');
    }
  }

  // Get monthly earnings
  static Future<ApiResponse> getMonthlyEarnings(String month, String year) async {
    try {
      return await _apiService.get('/earnings/monthly', queryParams: {
        'month': month,
        'year': year,
      });
    } catch (e) {
      return ApiResponse.error('Failed to get monthly earnings: ${e.toString()}');
    }
  }

  // Get earnings breakdown
  static Future<ApiResponse> getEarningsBreakdown({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      return await _apiService.get('/earnings/breakdown', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get earnings breakdown: ${e.toString()}');
    }
  }

  // Get bonuses
  static Future<ApiResponse> getBonuses({
    String? status, // 'active', 'completed', 'expired'
    int? page,
    int? limit,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      return await _apiService.get('/earnings/bonuses', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get bonuses: ${e.toString()}');
    }
  }

  // Get transactions
  static Future<ApiResponse> getTransactions({
    String? type, // 'ride_fare', 'bonus', 'penalty', 'withdrawal'
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (type != null) queryParams['type'] = type;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      return await _apiService.get('/earnings/transactions', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get transactions: ${e.toString()}');
    }
  }

  // Request withdrawal
  static Future<ApiResponse> requestWithdrawal(
    double amount,
    String bankAccountId,
  ) async {
    try {
      return await _apiService.post('/earnings/withdraw', body: {
        'amount': amount,
        'bank_account_id': bankAccountId,
      });
    } catch (e) {
      return ApiResponse.error('Failed to request withdrawal: ${e.toString()}');
    }
  }

  // Get withdrawal history
  static Future<ApiResponse> getWithdrawalHistory({
    int? page,
    int? limit,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      return await _apiService.get('/earnings/withdrawals', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get withdrawal history: ${e.toString()}');
    }
  }

  // Get performance metrics
  static Future<ApiResponse> getPerformanceMetrics({
    String? period,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (period != null) queryParams['period'] = period;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      return await _apiService.get('/earnings/performance', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get performance metrics: ${e.toString()}');
    }
  }
}
