# 🚨 RAZORPAY "UH OH! SOMETHING WENT WRONG" - COMPLETE FIX GUIDE

## 🔍 EXACT CAUSES & SOLUTIONS

### 1. **ENVIRONMENT MISMATCH (Most Common)**
```dart
❌ WRONG:
keyId: 'rzp_test_12345'  // Test key
orderId: 'order_live_67890' // Live order

✅ CORRECT:
keyId: 'rzp_test_12345'  // Test key  
orderId: 'order_Mxxxxxxx' // Test order (from test environment)
```

**Fix:**
- Test keys work only with test orders
- Live keys work only with live orders
- Check Razorpay dashboard to verify order environment

### 2. **INVALID ORDER ID FORMAT**
```dart
❌ WRONG:
orderId: ""                    // Empty
orderId: "order123"           // Wrong format
orderId: "expired_order_id"   // Expired (24h limit)

✅ CORRECT:
orderId: "order_Mxxxxxxxxxxxxx"  // Proper format
```

### 3. **WRONG AMOUNT FORMAT**
```dart
❌ WRONG:
amount: 100        // Rupees (should be paise)
amount: "100"      // String (should be integer)

✅ CORRECT:
amount: 10000      // Paise (₹100 = 10000 paise)
```

### 4. **AUTHENTICATION ISSUES**
```dart
❌ WRONG:
keyId: "rzp_test_wrong_key"
keySecret: "wrong_secret"

✅ CORRECT:
keyId: "rzp_test_RnX4Oatt9zSiqS"  // Your actual key
keySecret: "your_actual_secret"    // Your actual secret
```

---

## 🛠️ COMPLETE WORKING SOLUTION

### **Step 1: Fix Your Service Configuration**
```dart
// Update your razorpay_payment_service.dart
class RazorpayPaymentService {
  // 🔧 CRITICAL: Replace with your actual values
  static const String _keyId = 'rzp_test_RnX4Oatt9zSiqS';
  static const String _keySecret = 'your_actual_test_secret_here';  // ⚠️ ADD THIS
  static const String _baseUrl = 'https://backend.ridealmobility.com';
  
  static const bool _isTestMode = true; // Set false for production
}
```

### **Step 2: Proper Order Creation**
```dart
// Method 1: Direct Razorpay API (Recommended)
Future<Map<String, dynamic>> createRazorpayOrder({
  required double amount,
  required String receipt,
}) async {
  try {
    final amountInPaise = (amount * 100).round();
    
    // Validate minimum amount
    if (amountInPaise < 100) {
      throw Exception('Minimum amount is ₹1');
    }

    final requestBody = {
      'amount': amountInPaise,           // MUST be in paise
      'currency': 'INR',                // MUST be INR for India
      'receipt': receipt,               // MUST be unique
      'payment_capture': 1,             // Auto-capture
    };

    // Create Basic Auth
    final auth = base64Encode(utf8.encode('$_keyId:$_keySecret'));
    
    final response = await http.post(
      Uri.parse('https://api.razorpay.com/v1/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $auth',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'order_id': data['id'],      // This is your order_id
        'amount': data['amount'],
        'currency': data['currency'],
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Razorpay Error: ${error['error']['description']}');
    }
  } catch (e) {
    print('❌ Order creation failed: $e');
    return {'success': false, 'error': e.toString()};
  }
}
```

### **Step 3: Perfect Payment Opening**
```dart
Future<bool> openPayment({
  required String orderId,
  required double amount,
  required String customerName,
}) async {
  try {
    // Validate order ID format
    if (!orderId.startsWith('order_')) {
      throw Exception('Invalid order ID: $orderId');
    }

    final amountInPaise = (amount * 100).round();

    var options = {
      'key': _keyId,                    // Your key
      'order_id': orderId,              // From createRazorpayOrder
      'amount': amountInPaise,          // MUST match order amount
      'currency': 'INR',               
      'name': 'RiDeal Driver',
      'description': 'Subscription Payment',
      'timeout': 300,                   // 5 minutes
      'retry': {'enabled': true, 'max_count': 3},
      'prefill': {
        'name': customerName,
      },
    };

    print('📋 Opening Razorpay with:');
    print('  Key: ${options['key']}');
    print('  Order: ${options['order_id']}');
    print('  Amount: ${options['amount']} paise');

    _razorpay.open(options);
    return true;
  } catch (e) {
    print('❌ Failed to open payment: $e');
    return false;
  }
}
```

### **Step 4: Complete Payment Flow**
```dart
Future<void> processPayment({
  required double amount,
  required String customerName,
  required Function(Map<String, dynamic>) onSuccess,
  required Function(String) onError,
}) async {
  try {
    // Step 1: Create order
    final orderResult = await createRazorpayOrder(
      amount: amount,
      receipt: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!orderResult['success']) {
      onError('Order creation failed: ${orderResult['error']}');
      return;
    }

    // Step 2: Set up success callback
    this.onSuccess = (PaymentSuccessResponse response) async {
      print('🎉 Payment successful!');
      print('Payment ID: ${response.paymentId}');
      
      // Step 3: Verify with your backend
      final verification = await verifyPayment(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        signature: response.signature!,
      );
      
      onSuccess(verification);
    };

    this.onFailure = (PaymentFailureResponse response) {
      onError('Payment failed: ${response.message}');
    };

    // Step 4: Open payment
    final opened = await openPayment(
      orderId: orderResult['order_id'],
      amount: amount,
      customerName: customerName,
    );

    if (!opened) {
      onError('Failed to open payment gateway');
    }
  } catch (e) {
    onError('Payment process failed: $e');
  }
}
```

---

## 🧪 TESTING STEPS

### **1. Test with Minimal Setup**
```dart
// Test this first
final service = RazorpayPaymentService();

await service.processPayment(
  amount: 1.0,  // ₹1 for testing
  customerName: 'Test User',
  onSuccess: (result) {
    print('✅ Success: $result');
  },
  onError: (error) {
    print('❌ Error: $error');
  },
);
```

### **2. Debug Checklist**
```bash
✅ Check Razorpay dashboard for order creation
✅ Verify key environment (test/live) matches order
✅ Ensure amount is in paise (multiply by 100)
✅ Confirm internet connectivity
✅ Check device time is correct
✅ Test with different payment methods
```

### **3. Common Test Cards**
```
Success: 4111 1111 1111 1111
Failed:  4111 1111 1111 1112
CVV:     Any 3 digits
Expiry:  Any future date
OTP:     123456
```

---

## 🚨 CRITICAL ERRORS & FIXES

### **Error: "Invalid key id"**
```dart
❌ Problem: Wrong or missing key ID
✅ Fix: Get correct key from Razorpay dashboard > Settings > API Keys
```

### **Error: "Order does not exist"** 
```dart
❌ Problem: Order expired or wrong environment
✅ Fix: Create fresh order before each payment
```

### **Error: "Amount mismatch"**
```dart
❌ Problem: Payment amount ≠ order amount
✅ Fix: Use exact same amount for order and payment
```

### **Error: "Signature verification failed"**
```dart
❌ Problem: Wrong key secret or signature generation
✅ Fix: Use correct key secret from dashboard
```

---

## 📱 INTEGRATION EXAMPLE

```dart
// In your subscription controller
class SubscriptionController extends GetxController {
  final _paymentService = RazorpayPaymentService();
  
  Future<void> buySubscription(SubscriptionPlan plan) async {
    try {
      await _paymentService.processPayment(
        amount: plan.rate.toDouble(),
        customerName: await getDriverName(),
        onSuccess: (result) {
          print('✅ Payment verified successfully!');
          // Update subscription status
          updateSubscriptionStatus(true);
          Get.snackbar('Success', 'Subscription activated!');
        },
        onError: (error) {
          print('❌ Payment failed: $error');
          Get.snackbar('Error', error);
        },
      );
    } catch (e) {
      print('❌ Subscription purchase failed: $e');
      Get.snackbar('Error', 'Failed to process payment');
    }
  }
}
```

---

## 📞 STILL HAVING ISSUES?

### **Debug Steps:**
1. **Check Razorpay Dashboard** → Orders → Look for your order
2. **Enable Razorpay Logs** → Check for detailed error messages  
3. **Test Environment** → Use test cards first
4. **Network Check** → Ensure stable internet
5. **Restart App** → Clear any cached payment state

### **Contact Points:**
- **Razorpay Support**: support@razorpay.com
- **Test Integration**: Use their test environment first
- **Documentation**: https://razorpay.com/docs/

Your payment integration should now work perfectly! 🚀