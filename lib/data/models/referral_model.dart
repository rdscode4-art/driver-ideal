class ReferralFriend {
  final String name;
  final String phone;
  final double referrerBonus;
  final DateTime createdAt;

  ReferralFriend({
    required this.name,
    required this.phone,
    required this.referrerBonus,
    required this.createdAt,
  });

  factory ReferralFriend.fromJson(Map<String, dynamic> json) {
    return ReferralFriend(
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      referrerBonus: (json['referrerBonus'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class RewardScheme {
  final double referrerBonus;
  final double refereeBonus;

  RewardScheme({
    required this.referrerBonus,
    required this.refereeBonus,
  });

  factory RewardScheme.fromJson(Map<String, dynamic> json) {
    return RewardScheme(
      referrerBonus: (json['referrerBonus'] ?? 0).toDouble(),
      refereeBonus: (json['refereeBonus'] ?? 0).toDouble(),
    );
  }
}

class ReferralDashboardData {
  final bool success;
  final double totalEarnings;
  final int totalFriends;
  final List<ReferralFriend> friends;
  final RewardScheme? rewardScheme;

  ReferralDashboardData({
    required this.success,
    required this.totalEarnings,
    required this.totalFriends,
    required this.friends,
    this.rewardScheme,
  });

  factory ReferralDashboardData.fromJson(Map<String, dynamic> json) {
    return ReferralDashboardData(
      success: json['success'] ?? false,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      totalFriends: json['totalFriends'] ?? 0,
      friends: (json['friends'] as List<dynamic>?)
              ?.map((item) => ReferralFriend.fromJson(item))
              .toList() ??
          [],
      rewardScheme: json['rewardScheme'] != null
          ? RewardScheme.fromJson(json['rewardScheme'])
          : null,
    );
  }
}
