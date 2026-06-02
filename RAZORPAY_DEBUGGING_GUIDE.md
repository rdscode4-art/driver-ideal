# 🚨 Razorpay Payment Debugging Guide

## Common Error: "Uh oh! Something went wrong – Secured by Razorpay"

This generic error message can have several causes. Here's a comprehensive troubleshooting guide:

### 1. **Invalid Order ID** ❌
**Symptoms:**
- Payment gateway opens but fails immediately
- Error message appears without showing payment options

**Causes:**
- Order ID doesn't exist in Razorpay
- Order ID format is incorrect (should be: `order_xxxxxxxxxx`)
- Order was created with different API credentials

**Solutions:**
```javascript
// ✅ Correct order creation
const order = await razorpay.orders.create({
  amount: 10000,        // ✅ Amount in paise (₹100)
  currency: 'INR',      // ✅ Always INR for Indian payments
  receipt: 'rcpt_123',  // ✅ Unique receipt ID
  payment_capture: 1    // ✅ Auto-capture payment
});

// ❌ Wrong - amount in rupees
amount: 100  // Should be 10000 for ₹100

// ❌ Wrong - missing required fields
const order = await razorpay.orders.create({
  amount: 10000
  // Missing currency, receipt
});
```

### 2. **Wrong Key ID / Key Secret** 🔑
**Symptoms:**
- 401 Unauthorized errors
- "Authentication failed" in logs
- Orders not getting created

**Debug Steps:**
```javascript
// ✅ Check your keys
const razorpay = new Razorpay({
  key_id: 'rzp_test_RnX4Oatt9zSiqS',     // ✅ Your actual test key
  key_secret: 'YOUR_ACTUAL_KEY_SECRET'    // ✅ Your actual secret
});

// ❌ Common mistakes:
key_id: 'rzp_live_xxxxx'     // Using live key with test secret
key_secret: 'test_secret'    // Placeholder text, not actual secret
key_secret: undefined        // Not defined in environment
```

**Verification:**
```bash
# Test your credentials
curl -X POST https://api.razorpay.com/v1/orders \
  -H "Content-Type: application/json" \
  -u rzp_test_RnX4Oatt9zSiqS:YOUR_KEY_SECRET \
  -d '{
    "amount": 10000,
    "currency": "INR",
    "receipt": "test_receipt"
  }'
```

### 3. **Live/Test Environment Mismatch** 🔄
**Symptoms:**
- Orders created but payment fails
- "Order does not exist" errors

**Common Issues:**
```javascript
// ❌ Using live order with test key
Frontend: key: 'rzp_test_xxxxx'    // Test key
Backend:  order created with live credentials

// ❌ Using test order with live key
Frontend: key: 'rzp_live_xxxxx'    // Live key  
Backend:  order created with test credentials

// ✅ Correct - both test
Frontend: key: 'rzp_test_RnX4Oatt9zSiqS'
Backend:  razorpay = new Razorpay({ key_id: 'rzp_test_RnX4Oatt9zSiqS' })
```

### 4. **Expired Order/Signature** ⏰
**Symptoms:**
- Payment gateway opens but payment fails at the end
- "Order expired" or "Invalid signature" errors

**Solutions:**
```javascript
// ✅ Orders expire after 24 hours by default
// Create fresh order for each payment attempt

// ✅ Check order status before payment
const order = await razorpay.orders.fetch('order_xxxxx');
console.log('Order Status:', order.status); // Should be 'created'

// ❌ Don't reuse old order IDs
const oldOrderId = 'order_from_yesterday'; // This will fail
```

### 5. **Incorrect Amount Format** 💰
**Symptoms:**
- "Invalid amount" errors
- Payment amount shows wrong value

**Correct Format:**
```javascript
// ✅ Amount should be in paise (multiply by 100)
const amountInRupees = 299;
const amountInPaise = amountInRupees * 100; // 29900

const order = await razorpay.orders.create({
  amount: amountInPaise, // ✅ 29900 paise = ₹299
  currency: 'INR'
});

// Frontend
var options = {
  'amount': amountInPaise, // ✅ Same amount as order
};

// ❌ Common mistakes:
amount: 299,           // Should be 29900
amount: '299',         // Should be integer, not string
amount: 299.50 * 100   // Results in float, should be Math.round(299.50 * 100)
```

### 6. **Network/CORS Issues** 🌐
**Symptoms:**
- "Network error" in console
- CORS policy errors
- Timeouts during order creation

**Backend CORS Setup:**
```javascript
// ✅ Proper CORS configuration
const cors = require('cors');

app.use(cors({
  origin: [
    'https://localhost:3000',
    'https://yourdomain.com',
    'capacitor://localhost',  // For mobile apps
    'ionic://localhost'       // For Ionic apps
  ],
  credentials: true
}));
```

**Frontend Network Check:**
```dart
// ✅ Add timeout and error handling
try {
  final response = await http.post(
    Uri.parse('$baseUrl/create-order'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
    body: jsonEncode(orderData),
  ).timeout(Duration(seconds: 30));
  
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
} catch (e) {
  print('Network error: $e');
  // Handle appropriately
}
```

### 7. **Signature Verification Issues** 🔒
**Symptoms:**
- Payment succeeds but verification fails
- "Invalid signature" errors in backend

**Correct Verification:**
```javascript
// ✅ Correct signature verification
const crypto = require('crypto');

const expectedSignature = crypto
  .createHmac('sha256', 'YOUR_KEY_SECRET')
  .update(`${razorpay_order_id}|${razorpay_payment_id}`)
  .digest('hex');

if (expectedSignature === razorpay_signature) {
  // ✅ Payment is valid
  console.log('Payment verified successfully');
} else {
  // ❌ Invalid payment
  console.log('Signature verification failed');
}

// ❌ Common mistakes:
.update(`${razorpay_payment_id}|${razorpay_order_id}`) // Wrong order
.update(razorpay_order_id + razorpay_payment_id)       // Missing pipe
.createHmac('sha256', 'wrong_secret')                   // Wrong secret
```

### 8. **Mobile App Specific Issues** 📱
**Flutter/React Native:**
```dart
// ✅ Add proper permissions in AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

// ✅ Handle app lifecycle during payment
@override
void initState() {
  super.initState();
  _razorpay = Razorpay();
  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
}

@override
void dispose() {
  super.dispose();
  _razorpay.clear(); // ✅ Important: Clear listeners
}
```

## 🔧 Debugging Checklist

### Before Payment:
- [ ] Verify Razorpay credentials are correct
- [ ] Check test/live environment consistency
- [ ] Validate order creation API response
- [ ] Confirm order amount is in paise
- [ ] Test network connectivity

### During Payment:
- [ ] Monitor browser/app console for errors
- [ ] Check if payment gateway UI loads properly
- [ ] Verify payment options are available
- [ ] Check for CORS errors in network tab

### After Payment:
- [ ] Validate payment response structure
- [ ] Test signature verification logic
- [ ] Check payment status in Razorpay dashboard
- [ ] Verify webhook delivery (if using webhooks)

### Quick Test Script:
```bash
# Test order creation
curl -X POST https://your-backend.com/create-order \
  -H "Content-Type: application/json" \
  -d '{"amount": 10000, "currency": "INR", "receipt": "test_001"}'

# Test payment verification  
curl -X POST https://your-backend.com/verify-payment \
  -H "Content-Type: application/json" \
  -d '{
    "razorpay_order_id": "order_xxxxx",
    "razorpay_payment_id": "pay_xxxxx", 
    "razorpay_signature": "signature_xxxxx"
  }'
```

## 📞 Getting Help

If you're still facing issues:

1. **Check Razorpay Dashboard:** Look for failed payments and error details
2. **Enable Webhook Logs:** See real-time payment events
3. **Use Razorpay Test Cards:** Ensure you're testing correctly
4. **Contact Razorpay Support:** They have excellent technical support

### Test Cards for Testing:
```
Success: 4111 1111 1111 1111
Failed:  4111 1111 1111 1112
CVV:     Any 3 digits
Expiry:  Any future date
```

Remember: Always test payments thoroughly before going live! 🚀