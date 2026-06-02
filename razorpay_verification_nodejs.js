const crypto = require('crypto');
const express = require('express');
const app = express();

// Middleware
app.use(express.json());

// Razorpay Configuration
const RAZORPAY_KEY_ID = 'rzp_test_RnX4Oatt9zSiqS';
const RAZORPAY_SECRET = 'C79lUWsMza7uO849xeo0no5c';

/**
 * ✅ CORRECT Razorpay Signature Verification Function
 * Formula: expectedSignature = HMAC_SHA256(order_id + "|" + payment_id, SECRET)
 */
function verifyRazorpaySignature(orderId, paymentId, receivedSignature, secret) {
    try {
        console.log('🔍 ════════════════════════════════════════════════════════');
        console.log('🔍           RAZORPAY SIGNATURE VERIFICATION');
        console.log('🔍 ════════════════════════════════════════════════════════');
        console.log('📋 Order ID:', orderId);
        console.log('💳 Payment ID:', paymentId);
        console.log('🔐 Received Signature:', receivedSignature);
        console.log('🔑 Secret Key:', secret.substring(0, 10) + '...');
        
        // Step 1: Create the payload (CRITICAL: order_id + "|" + payment_id)
        const payload = orderId + "|" + paymentId;
        console.log('📦 Payload:', payload);
        
        // Step 2: Generate expected signature using HMAC SHA256
        const expectedSignature = crypto
            .createHmac('sha256', secret)
            .update(payload)
            .digest('hex');
        
        console.log('🎯 Expected Signature:', expectedSignature);
        console.log('🔄 Received Signature:', receivedSignature);
        
        // Step 3: Safe comparison (prevents timing attacks)
        const isValid = crypto.timingSafeEqual(
            Buffer.from(expectedSignature, 'hex'),
            Buffer.from(receivedSignature, 'hex')
        );
        
        console.log('✅ Signature Valid:', isValid);
        console.log('🔍 ════════════════════════════════════════════════════════');
        
        return isValid;
    } catch (error) {
        console.error('❌ Signature verification error:', error);
        return false;
    }
}

/**
 * 🧪 TEST FUNCTION - Verify with your example data
 */
function testSignatureVerification() {
    console.log('🧪 ════════════════════════════════════════════════════════');
    console.log('🧪           TESTING SIGNATURE VERIFICATION');
    console.log('🧪 ════════════════════════════════════════════════════════');
    
    const testData = {
        orderId: 'order_RpTmsJFWeZ4FOI',
        paymentId: 'pay_RpTnA8xEtptd8c',
        receivedSignature: 'fcb552fb0a7187feefb1f1c6ba2a6b80c1195ed26ed0a537d0b512fad0e22b5c',
        secret: 'C79lUWsMza7uO849xeo0no5c'
    };
    
    const result = verifyRazorpaySignature(
        testData.orderId,
        testData.paymentId,
        testData.receivedSignature,
        testData.secret
    );
    
    console.log('🎯 Test Result:', result ? '✅ PASS' : '❌ FAIL');
    
    // Also generate and print the expected signature for debugging
    const payload = testData.orderId + "|" + testData.paymentId;
    const expectedSignature = crypto
        .createHmac('sha256', testData.secret)
        .update(payload)
        .digest('hex');
    
    console.log('📋 Expected Signature for your data:', expectedSignature);
    console.log('🧪 ════════════════════════════════════════════════════════');
}

/**
 * 🚀 API ENDPOINT - Verify subscription payment
 */
app.post('/verify-subscription-payment', (req, res) => {
    try {
        console.log('📡 ════════════════════════════════════════════════════════');
        console.log('📡         SUBSCRIPTION PAYMENT VERIFICATION API');
        console.log('📡 ════════════════════════════════════════════════════════');
        
        const {
            driverId,
            planId,
            razorpay_payment_id,
            razorpay_order_id,
            razorpay_signature
        } = req.body;
        
        console.log('📤 Request Body:', req.body);
        
        // Validate required fields
        if (!razorpay_payment_id || !razorpay_order_id || !razorpay_signature) {
            return res.status(400).json({
                success: false,
                message: 'Missing required payment parameters'
            });
        }
        
        // Verify signature
        const isValidSignature = verifyRazorpaySignature(
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature,
            RAZORPAY_SECRET
        );
        
        if (!isValidSignature) {
            console.log('❌ Signature verification failed');
            return res.status(400).json({
                success: false,
                message: 'Invalid payment signature'
            });
        }
        
        console.log('✅ Signature verification successful');
        
        // TODO: Update subscription in database
        // Example:
        // await updateUserSubscription(driverId, planId, {
        //     paymentId: razorpay_payment_id,
        //     orderId: razorpay_order_id,
        //     status: 'active',
        //     activatedAt: new Date()
        // });
        
        console.log('🎉 Subscription activated for driver:', driverId);
        
        return res.status(200).json({
            success: true,
            message: 'Payment verified and subscription activated',
            data: {
                driverId,
                planId,
                paymentId: razorpay_payment_id,
                orderId: razorpay_order_id,
                status: 'active',
                verifiedAt: new Date().toISOString()
            }
        });
        
    } catch (error) {
        console.error('❌ Verification API error:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error during verification'
        });
    }
});

/**
 * 🚀 START SERVER
 */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Razorpay verification server running on port ${PORT}`);
    
    // Run test on startup
    testSignatureVerification();
});

// Export for testing
module.exports = { verifyRazorpaySignature, testSignatureVerification };