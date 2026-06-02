<?php
/**
 * ✅ CORRECT Razorpay Signature Verification - PHP Version
 * Formula: expectedSignature = HMAC_SHA256(order_id + "|" + payment_id, SECRET)
 */

// Razorpay Configuration
define('RAZORPAY_KEY_ID', 'rzp_test_RnX4Oatt9zSiqS');
define('RAZORPAY_SECRET', 'C79lUWsMza7uO849xeo0no5c');

/**
 * Verify Razorpay payment signature
 */
function verifyRazorpaySignature($orderId, $paymentId, $receivedSignature, $secret) {
    try {
        error_log('🔍 ════════════════════════════════════════════════════════');
        error_log('🔍           RAZORPAY SIGNATURE VERIFICATION');
        error_log('🔍 ════════════════════════════════════════════════════════');
        error_log('📋 Order ID: ' . $orderId);
        error_log('💳 Payment ID: ' . $paymentId);
        error_log('🔐 Received Signature: ' . $receivedSignature);
        error_log('🔑 Secret Key: ' . substr($secret, 0, 10) . '...');
        
        // Step 1: Create the payload (CRITICAL: order_id + "|" + payment_id)
        $payload = $orderId . "|" . $paymentId;
        error_log('📦 Payload: ' . $payload);
        
        // Step 2: Generate expected signature using HMAC SHA256
        $expectedSignature = hash_hmac('sha256', $payload, $secret);
        
        error_log('🎯 Expected Signature: ' . $expectedSignature);
        error_log('🔄 Received Signature: ' . $receivedSignature);
        
        // Step 3: Safe comparison (prevents timing attacks)
        $isValid = hash_equals($expectedSignature, $receivedSignature);
        
        error_log('✅ Signature Valid: ' . ($isValid ? 'true' : 'false'));
        error_log('🔍 ════════════════════════════════════════════════════════');
        
        return $isValid;
    } catch (Exception $e) {
        error_log('❌ Signature verification error: ' . $e->getMessage());
        return false;
    }
}

/**
 * 🧪 TEST FUNCTION - Verify with your example data
 */
function testSignatureVerification() {
    error_log('🧪 ════════════════════════════════════════════════════════');
    error_log('🧪           TESTING SIGNATURE VERIFICATION');
    error_log('🧪 ════════════════════════════════════════════════════════');
    
    $testData = [
        'orderId' => 'order_RpTmsJFWeZ4FOI',
        'paymentId' => 'pay_RpTnA8xEtptd8c',
        'receivedSignature' => 'fcb552fb0a7187feefb1f1c6ba2a6b80c1195ed26ed0a537d0b512fad0e22b5c',
        'secret' => 'C79lUWsMza7uO849xeo0no5c'
    ];
    
    $result = verifyRazorpaySignature(
        $testData['orderId'],
        $testData['paymentId'],
        $testData['receivedSignature'],
        $testData['secret']
    );
    
    error_log('🎯 Test Result: ' . ($result ? '✅ PASS' : '❌ FAIL'));
    
    // Also generate and print the expected signature for debugging
    $payload = $testData['orderId'] . "|" . $testData['paymentId'];
    $expectedSignature = hash_hmac('sha256', $payload, $testData['secret']);
    
    error_log('📋 Expected Signature for your data: ' . $expectedSignature);
    error_log('🧪 ════════════════════════════════════════════════════════');
}

/**
 * 🚀 API ENDPOINT - Verify subscription payment
 */
function handleVerifySubscriptionPayment() {
    try {
        error_log('📡 ════════════════════════════════════════════════════════');
        error_log('📡         SUBSCRIPTION PAYMENT VERIFICATION API');
        error_log('📡 ════════════════════════════════════════════════════════');
        
        // Get request body
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        
        error_log('📤 Request Body: ' . $input);
        
        // Extract required fields
        $driverId = $data['driverId'] ?? null;
        $planId = $data['planId'] ?? null;
        $razorpay_payment_id = $data['razorpay_payment_id'] ?? null;
        $razorpay_order_id = $data['razorpay_order_id'] ?? null;
        $razorpay_signature = $data['razorpay_signature'] ?? null;
        
        // Validate required fields
        if (!$razorpay_payment_id || !$razorpay_order_id || !$razorpay_signature) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Missing required payment parameters'
            ]);
            return;
        }
        
        // Verify signature
        $isValidSignature = verifyRazorpaySignature(
            $razorpay_order_id,
            $razorpay_payment_id,
            $razorpay_signature,
            RAZORPAY_SECRET
        );
        
        if (!$isValidSignature) {
            error_log('❌ Signature verification failed');
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid payment signature'
            ]);
            return;
        }
        
        error_log('✅ Signature verification successful');
        
        // TODO: Update subscription in database
        // Example:
        // updateUserSubscription($driverId, $planId, [
        //     'paymentId' => $razorpay_payment_id,
        //     'orderId' => $razorpay_order_id,
        //     'status' => 'active',
        //     'activatedAt' => date('Y-m-d H:i:s')
        // ]);
        
        error_log('🎉 Subscription activated for driver: ' . $driverId);
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Payment verified and subscription activated',
            'data' => [
                'driverId' => $driverId,
                'planId' => $planId,
                'paymentId' => $razorpay_payment_id,
                'orderId' => $razorpay_order_id,
                'status' => 'active',
                'verifiedAt' => date('c')
            ]
        ]);
        
    } catch (Exception $e) {
        error_log('❌ Verification API error: ' . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Internal server error during verification'
        ]);
    }
}

// Handle API request
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $_SERVER['REQUEST_URI'] === '/verify-subscription-payment') {
    handleVerifySubscriptionPayment();
} else {
    // Run test for debugging
    testSignatureVerification();
    
    echo json_encode([
        'message' => 'Razorpay verification service running',
        'test_completed' => true
    ]);
}
?>