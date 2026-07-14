import 'package:get/get.dart';
import '../data/models/referral_model.dart';
import '../services/referral_api_service.dart';

class ReferralController extends GetxController {
  final ReferralApiService _apiService = ReferralApiService();

  var isLoading = true.obs;
  var referralData = Rxn<ReferralDashboardData>();

  @override
  void onInit() {
    super.onInit();
    fetchReferrals();
  }

  Future<void> fetchReferrals() async {
    isLoading(true);
    try {
      final data = await _apiService.getDriverReferrals();
      if (data != null) {
        referralData.value = data;
      }
    } finally {
      isLoading(false);
    }
  }
}
