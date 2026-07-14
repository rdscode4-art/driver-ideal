import 'package:get/get.dart';
import '../data/models/referral_model.dart';
import 'non_vehichle_referral_api_service.dart';

class NonVehicleReferralController extends GetxController {
  final NonVehicleReferralApiService _apiService = NonVehicleReferralApiService();

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
