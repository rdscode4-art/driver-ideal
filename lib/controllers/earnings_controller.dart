import 'package:get/get.dart';
import '../data/models/earnings_model.dart';
import '../services/earnings_service.dart';
import '../core/utils/app_snackbar.dart';

class EarningsController extends GetxController {
  final EarningsService _earningsService = EarningsService();
  final earnings = Earnings.empty().obs;
  final isLoading = false.obs;
  final error = RxString('');

  // Observable values for different earnings periods
  final todayEarnings = RxDouble(0.0);
  final weekEarnings = RxDouble(0.0);
  final monthEarnings = RxDouble(0.0);
  final totalEarnings = RxDouble(0.0);
  final walletEarnings = RxDouble(0.0);
  final tripEarnings = RxDouble(0.0);

  // Bonus and incentive observables
  final ratingBonus = RxDouble(0.0);
  final referralBonus = RxDouble(0.0);
  final weeklyGoalBonus = RxDouble(0.0);
  final festivalBonus = RxDouble(0.0);

  // Driver performance observables
  final isPeakHour = RxBool(false);
  final consecutiveTrips = RxInt(0);
  final driverRating = RxDouble(4.5);
  final referredDrivers = RxInt(0);
  final weeklyTripsCompleted = RxInt(0);
  final weeklyTripsTarget = RxInt(25);
  final isFestivalBonusActive = RxBool(true);

  // Wallet related observables
  final walletBalance = RxDouble(0.0);
  final availableForPayout = RxDouble(0.0);
  final pendingPayouts = RxDouble(0.0);
  final isProcessingPayout = false.obs;
  final payoutHistory = <PayoutTransaction>[].obs;
  final minimumPayoutAmount = 100.0; // Minimum ₹100 for payout

  @override
  void onInit() {
    super.onInit();
    fetchEarnings();
    fetchWalletData();
  }

  Future<void> fetchEarnings() async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await _earningsService.getEarnings();

      if (result['success']) {
        final Earnings earningsData = result['earnings'];
        earnings.value = earningsData;

        // Update all earnings values - DO NOT MODIFY THESE
        todayEarnings.value = earningsData.today;
        weekEarnings.value = earningsData.week;
        monthEarnings.value = earningsData.month;
        totalEarnings.value = earningsData.total; // THIS IS THE FIX - Use API total directly
        tripEarnings.value = earningsData.total;

        // Update wallet balance
        walletBalance.value = earningsData.total;

        // Calculate bonuses (for display only)
        await _updateBonusData();
        // REMOVED: _calculateTotalEarnings() - Don't add bonuses to total!
      } else {
        error.value = result['message'];
        // Do not show snackbar at startup if the user just isn't logged in yet
        if (result['message'] != 'Authentication required. Please login again.') {
          showErrorSnackBar(result['message'] ?? 'Failed to fetch earnings', title: 'Error');
        }
      }
    } catch (e) {
      error.value = 'Failed to fetch earnings: $e';
      // Get.snackbar('Error', 'Failed to fetch earnings: $e');

      // Set mock data for development
      _setMockData();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWalletData() async {
    try {
      final result = await _earningsService.getWalletData();

      if (result['success']) {
        final data = result['data'];
        // Robust parsing for wallet balance/earnings
        double balance = 0.0;
        bool balanceFound = false;

        // Check 1: Direct key at root
        if (data.containsKey('wallet')) {
          balance = (data['wallet'] ?? 0.0).toDouble();
          balanceFound = true;
        } else if (data.containsKey('walletBalance')) {
          balance = (data['walletBalance'] ?? 0.0).toDouble();
          balanceFound = true;
        } else if (data.containsKey('earnings')) {
          balance = (data['earnings'] ?? 0.0).toDouble();
          balanceFound = true;
        } 
        
        // Check 2: Nested inside 'data' key
        if (!balanceFound && data.containsKey('data')) {
          final nestedData = data['data'];
          if (nestedData is Map) {
            if (nestedData.containsKey('wallet')) {
              balance = (nestedData['wallet'] ?? 0.0).toDouble();
              balanceFound = true;
            } else if (nestedData.containsKey('walletBalance')) {
              balance = (nestedData['walletBalance'] ?? 0.0).toDouble();
              balanceFound = true;
            } else if (nestedData.containsKey('earnings')) {
              balance = (nestedData['earnings'] ?? 0.0).toDouble();
              balanceFound = true;
            }
          }
        }
        
        // Check 3: Alternative keys
        if (!balanceFound) {
          final keys = ['amount', 'total', 'currentBalance'];
          for (final key in keys) {
            if (data.containsKey(key)) {
              balance = (data[key] ?? 0.0).toDouble();
              balanceFound = true;
              break;
            } else if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey(key)) {
              balance = (data['data'][key] ?? 0.0).toDouble();
              balanceFound = true;
              break;
            }
          }
        }

        if (balanceFound) {
          walletBalance.value = balance;
          walletEarnings.value = balance;
          totalEarnings.value = balance;
        } else {
          walletBalance.value = 0.0;
          walletEarnings.value = 0.0;
        }
        
        availableForPayout.value = (data['availableForPayout'] ?? walletBalance.value).toDouble();
        pendingPayouts.value = (data['pendingPayouts'] ?? 0.0).toDouble();

        // Fetch payout history
        final historyResult = await _earningsService.getPayoutHistory();
        if (historyResult['success']) {
          payoutHistory.value = (historyResult['data'] as List)
              .map((item) => PayoutTransaction.fromJson(item))
              .toList();
        }
      } else {
        // Don't show error snackbar for wallet data
        print('Wallet data error: ${result['message']}');
      }
    } catch (e) {
      print('Error fetching wallet data: $e');
      // Set mock data for development
      walletBalance.value = totalEarnings.value;
      availableForPayout.value = totalEarnings.value * 0.8; // 80% available
      pendingPayouts.value = totalEarnings.value * 0.2; // 20% pending
    }
  }

  Future<bool> requestPayout(double amount, String accountNumber, String ifscCode, String accountHolderName) async {
    if (amount < minimumPayoutAmount) {
      showWarningSnackBar(
        'Minimum payout amount is ₹${minimumPayoutAmount.toStringAsFixed(0)}',
        title: 'Invalid Amount',
      );
      return false;
    }

    if (amount > availableForPayout.value) {
      showWarningSnackBar(
        'You can only withdraw up to ₹${availableForPayout.value.toStringAsFixed(2)}',
        title: 'Insufficient Balance',
      );
      return false;
    }

    try {
      isProcessingPayout.value = true;

      final result = await _earningsService.requestPayout({
        'amount': amount,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'accountHolderName': accountHolderName,
      });

      if (result['success']) {
        // Update wallet balance
        availableForPayout.value -= amount;
        pendingPayouts.value += amount;

        // Add to history
        payoutHistory.insert(0, PayoutTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          status: 'pending',
          requestedAt: DateTime.now(),
          accountNumber: accountNumber,
          ifscCode: ifscCode,
        ));

        showSuccessSnackBar(
          'Your payout of ₹${amount.toStringAsFixed(2)} has been submitted. It will be processed within 2-3 business days.',
          title: 'Payout Requested',
        );

        return true;
      } else {
        showErrorSnackBar(result['message'] ?? 'Failed to process payout', title: 'Error');
        return false;
      }
    } catch (e) {
      showErrorSnackBar('Network error occurred. Please try again.', title: 'Error');
      return false;
    } finally {
      isProcessingPayout.value = false;
    }
  }

  Future<void> _updateBonusData() async {
    try {
      // These bonuses are POTENTIAL earnings, not actual earnings
      // They are displayed separately to motivate drivers

      // Rating bonus for maintaining high rating
      ratingBonus.value = driverRating.value >= 4.8 ? 300.0 : 0.0;

      // Referral bonus
      referralBonus.value = referredDrivers.value * 500.0;

      // Weekly goal bonus
      weeklyGoalBonus.value = weeklyTripsCompleted.value >= weeklyTripsTarget.value ? 1000.0 : 0.0;

      // Festival bonus (active during festival periods)
      festivalBonus.value = isFestivalBonusActive.value ? 500.0 : 0.0;

    } catch (e) {
      print('Error updating bonus data: $e');
    }
  }

  void _calculateTotalEarnings() {
    // THIS METHOD SHOULD NOT BE CALLED!
    // Total earnings come from API only
    // Bonuses are separate and should not be added to total
    
    // If you need total WITH bonuses for some other purpose, create a separate variable:
    // totalWithBonuses.value = totalEarnings.value + ratingBonus.value + referralBonus.value + ...;
  }

  void _setMockData() {
    // Set mock data for development/testing
    tripEarnings.value = 1250.0;
    todayEarnings.value = 450.0;
    weekEarnings.value = 3200.0;
    monthEarnings.value = 12800.0;
    totalEarnings.value = 12800.0; // Set total directly, don't calculate

    // Mock performance data
    consecutiveTrips.value = 4;
    driverRating.value = 4.9;
    referredDrivers.value = 2;
    weeklyTripsCompleted.value = 18;
    weeklyTripsTarget.value = 25;
    isFestivalBonusActive.value = true;

    _updateBonusData();
    // REMOVED: _calculateTotalEarnings() - Don't add bonuses to total!
  }

  // Method to update driver performance (would be called from other parts of the app)
  void updateConsecutiveTrips(int trips) {
    consecutiveTrips.value = trips;
    _updateBonusData();
    // REMOVED: _calculateTotalEarnings()
  }

  void updateDriverRating(double rating) {
    driverRating.value = rating;
    _updateBonusData();
    // REMOVED: _calculateTotalEarnings()
  }

  void updateWeeklyProgress(int completed) {
    weeklyTripsCompleted.value = completed;
    _updateBonusData();
    // REMOVED: _calculateTotalEarnings()
  }

  // Method to refresh earnings data
  Future<void> refreshEarnings() => fetchEarnings();

  Future<void> refreshWallet() => fetchWalletData();

  Future<void> refreshAll() async {
    await Future.wait([
      fetchEarnings(),
      fetchWalletData(),
    ]);
  }
}

// Payout Transaction Model
class PayoutTransaction {
  final String id;
  final double amount;
  final String status; // 'pending', 'completed', 'failed'
  final DateTime requestedAt;
  final DateTime? completedAt;
  final String accountNumber;
  final String ifscCode;
  final String? transactionId;

  PayoutTransaction({
    required this.id,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    required this.accountNumber,
    required this.ifscCode,
    this.transactionId,
  });

  factory PayoutTransaction.fromJson(Map<String, dynamic> json) {
    return PayoutTransaction(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      transactionId: json['transactionId'],
    );
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return 'XXXX${accountNumber.substring(accountNumber.length - 4)}';
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Processing';
      case 'completed':
        return 'completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }
}