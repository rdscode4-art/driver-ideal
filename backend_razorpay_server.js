const express = require('express');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const cors = require('cors');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Razorpay Configuration
const razorpay = new Razorpay({
  key_id: 'rzp_test_RnX4Oatt9zSiqS', // Your test key ID
  key_secret: 'YOUR_TEST_KEY_SECRET', // Add your test key secret
});

// STEP 1: Create Razorpay Order
app.post('/create-razorpay-order', async (req, res) => {
  try {
    console.log('📡 Creating Razorpay order...');
    console.log('📤 Request Body:', JSON.stringify(req.body, null, 2));

    const { amount, currency = 'INR', receipt, payment_capture = 1 } = req.body;

    // Validate required fields
    if (!amount || !receipt) {
      return res.status(400).json({
        success: false,
        message: 'Amount and receipt are required',
      });
    }

    // Validate amount (should be in paise)
    if (amount < 100) {
      return res.status(400).json({
        success: false,
        message: 'Minimum amount is ₹1 (100 paise)',
      });
    }

    const orderOptions = {
      amount: parseInt(amount), // Amount in paise
      currency: currency,
      receipt: receipt,
      payment_capture: payment_capture,
    };

    console.log('🏦 Razorpay Order Options:', orderOptions);

    const order = await razorpay.orders.create(orderOptions);

    console.log('✅ Razorpay order created successfully');
    console.log('📋 Order Details:', JSON.stringify(order, null, 2));

    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
      receipt: order.receipt,
      status: order.status,
    });
  } catch (error) {
    console.error('❌ Error creating Razorpay order:', error);
    
    // Handle specific Razorpay errors
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.error.description || 'Razorpay API error',
        error_code: error.error.code,
      });
    }

    res.status(500).json({
      success: false,
      message: 'Internal server error while creating order',
      error: error.message,
    });
  }
});

// STEP 2: Verify Razorpay Payment
app.post('/verify-subscription-payment', async (req, res) => {
  try {
    console.log('🔍 Verifying Razorpay payment...');
    console.log('📤 Request Body:', JSON.stringify(req.body, null, 2));

    const {
      driverId,
      planId,
      razorpay_payment_id,
      razorpay_order_id,
      razorpay_signature,
    } = req.body;

    // Validate required fields
    if (!razorpay_payment_id || !razorpay_order_id || !razorpay_signature) {
      return res.status(400).json({
        success: false,
        message: 'Payment ID, Order ID, and Signature are required',
      });
    }

    // Check for test signature (for testing purposes)
    if (razorpay_signature.startsWith('test_signature_')) {
      console.log('🧪 Test signature detected, bypassing verification');
      return res.status(200).json({
        success: true,
        message: 'Test payment verified successfully',
        data: {
          payment_id: razorpay_payment_id,
          order_id: razorpay_order_id,
          status: 'captured',
          expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        },
      });
    }

    // STEP 3: Verify signature using HMAC SHA256
    const expectedSignature = crypto
      .createHmac('sha256', 'YOUR_TEST_KEY_SECRET') // Use your actual key secret
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    console.log('🔒 Expected Signature:', expectedSignature);
    console.log('🔒 Received Signature:', razorpay_signature);

    if (expectedSignature !== razorpay_signature) {
      console.error('❌ Signature verification failed');
      return res.status(400).json({
        success: false,
        message: 'Invalid payment signature',
        error: 'SIGNATURE_VERIFICATION_FAILED',
      });
    }

    console.log('✅ Signature verified successfully');

    // STEP 4: Fetch payment details from Razorpay
    const payment = await razorpay.payments.fetch(razorpay_payment_id);

    console.log('💳 Payment Details:', JSON.stringify(payment, null, 2));

    // Validate payment status
    if (payment.status !== 'captured') {
      return res.status(400).json({
        success: false,
        message: `Payment status is ${payment.status}, expected captured`,
        error: 'PAYMENT_NOT_CAPTURED',
      });
    }

    // STEP 5: Update subscription in your database
    // Add your database logic here
    const subscriptionData = {
      driver_id: driverId,
      plan_id: planId,
      payment_id: razorpay_payment_id,
      order_id: razorpay_order_id,
      amount: payment.amount,
      currency: payment.currency,
      status: 'active',
      start_date: new Date().toISOString(),
      expiry_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days
      payment_method: payment.method,
      created_at: new Date().toISOString(),
    };

    console.log('💾 Subscription Data to Save:', subscriptionData);

    // TODO: Save to your database
    // await subscriptionService.createSubscription(subscriptionData);

    res.status(200).json({
      success: true,
      message: 'Payment verified and subscription activated successfully',
      data: {
        subscription_id: `sub_${Date.now()}`, // Generate or get from DB
        payment_id: razorpay_payment_id,
        order_id: razorpay_order_id,
        amount: payment.amount,
        currency: payment.currency,
        status: 'active',
        expiryDate: subscriptionData.expiry_date,
        payment_method: payment.method,
      },
    });
  } catch (error) {
    console.error('❌ Error verifying payment:', error);

    // Handle specific Razorpay errors
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.error.description || 'Razorpay API error',
        error_code: error.error.code,
      });
    }

    res.status(500).json({
      success: false,
      message: 'Internal server error during verification',
      error: error.message,
    });
  }
});

// STEP 6: Get Payment Details (Optional)
app.get('/payment/:payment_id', async (req, res) => {
  try {
    const { payment_id } = req.params;
    
    console.log(`📋 Fetching payment details for: ${payment_id}`);
    
    const payment = await razorpay.payments.fetch(payment_id);
    
    res.status(200).json({
      success: true,
      payment: payment,
    });
  } catch (error) {
    console.error('❌ Error fetching payment:', error);
    
    res.status(500).json({
      success: false,
      message: 'Failed to fetch payment details',
      error: error.message,
    });
  }
});

// STEP 7: Refund Payment (Optional)
app.post('/refund-payment', async (req, res) => {
  try {
    const { payment_id, amount, reason = 'requested_by_customer' } = req.body;
    
    console.log(`💸 Processing refund for payment: ${payment_id}`);
    
    const refund = await razorpay.payments.refund(payment_id, {
      amount: amount, // Amount in paise, leave empty for full refund
      reason: reason,
    });
    
    console.log('✅ Refund processed:', refund);
    
    res.status(200).json({
      success: true,
      message: 'Refund processed successfully',
      refund: refund,
    });
  } catch (error) {
    console.error('❌ Error processing refund:', error);
    
    res.status(500).json({
      success: false,
      message: 'Failed to process refund',
      error: error.message,
    });
  }
});

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Razorpay payment server is running',
    timestamp: new Date().toISOString(),
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('🚨 Unhandled error:', error);
  
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: error.message,
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.originalUrl,
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Razorpay payment server running on port ${PORT}`);
  console.log(`🏥 Health check: https://localhost:${PORT}/health`);
  console.log(`📡 Create order: POST https://localhost:${PORT}/create-razorpay-order`);
  console.log(`🔍 Verify payment: POST https://localhost:${PORT}/verify-subscription-payment`);
});

module.exports = app;