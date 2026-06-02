class WalletModel {
  final bool success;
  final double wallet;
  final double earnings;

  WalletModel({
    required this.success,
    required this.wallet,
    required this.earnings,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      success: json['success'] ?? false,
      wallet: (json['wallet'] ?? 0).toDouble(),
      earnings: (json['earnings'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'wallet': wallet,
      'earnings': earnings,
    };
  }

  // Calculated properties for wallet features
  double get availableForPayout => wallet * 0.8; // 80% available for payout
  double get pendingPayouts => wallet * 0.2; // 20% pending
  double get totalBalance => wallet;

  @override
  String toString() {
    return 'WalletModel(success: $success, wallet: $wallet, earnings: $earnings)';
  }
}
