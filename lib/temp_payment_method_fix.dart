  import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:rideal_driver/presentation/payment_integration_helper.dart';

import 'controllers/ongoing_ride_controller.dart';

/// Complete ride with selected payment method
  void _completeRideWithPaymentMethod(
    OngoingRideController controller,
    String paymentMethod,
    RxBool isCompleting,
  ) async {
    // Use the PaymentIntegrationHelper that handles the payment-specific API call
    await PaymentIntegrationHelper.completeRideWithPaymentMethod(
      controller,
      paymentMethod,
      isCompleting,
    );
  }

