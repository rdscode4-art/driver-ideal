<?php
/**
 * 🧪 PHP SIGNATURE VERIFICATION TESTER
 */

function testPHPSignature() {
    echo "🧪 ════════════════════════════════════════════════════════\n";
    echo "🧪         PHP RAZORPAY SIGNATURE VERIFICATION TESTER\n";
    echo "🧪 ════════════════════════════════════════════════════════\n";
    
    // Your actual data from the failed verification
    $testData = [
        'orderId' => 'order_RpTmsJFWeZ4FOI',
        'paymentId' => 'pay_RpTnA8xEtptd8c',
        'expectedSignature' => 'fcb552fb0a7187feefb1f1c6ba2a6b80c1195ed26ed0a537d0b512fad0e22b5c',
        'secret' => 'C79lUWsMza7uO849xeo0no5c'
    ];
    
    echo "📋 Test Data:\n";
    echo "   Order ID: " . $testData['orderId'] . "\n";
    echo "   Payment ID: " . $testData['paymentId'] . "\n";
    echo "   Expected Signature: " . $testData['expectedSignature'] . "\n";
    echo "   Secret Key: " . substr($testData['secret'], 0, 10) . "...\n";
    echo "\n";
    
    // Step 1: Create payload
    $payload = $testData['orderId'] . "|" . $testData['paymentId'];
    echo "📦 Payload Formula: order_id + \"|\" + payment_id\n";
    echo "📦 Actual Payload: " . $payload . "\n";
    echo "\n";
    
    // Step 2: Generate signature
    $generatedSignature = hash_hmac('sha256', $payload, $testData['secret']);
    
    echo "🎯 Generated Signature: " . $generatedSignature . "\n";
    echo "🔄 Expected Signature:  " . $testData['expectedSignature'] . "\n";
    echo "\n";
    
    // Step 3: Compare
    $matches = hash_equals($generatedSignature, $testData['expectedSignature']);
    echo "✅ Signatures Match: " . ($matches ? '🎉 YES' : '❌ NO') . "\n";
    
    if (!$matches) {
        echo "\n";
        echo "🔍 DEBUGGING INFO:\n";
        echo "   Generated Length: " . strlen($generatedSignature) . "\n";
        echo "   Expected Length:  " . strlen($testData['expectedSignature']) . "\n";
        echo "   Generated (first 20): " . substr($generatedSignature, 0, 20) . "\n";
        echo "   Expected (first 20):  " . substr($testData['expectedSignature'], 0, 20) . "\n";
    }
    
    echo "🧪 ════════════════════════════════════════════════════════\n";
    
    return $matches;
}

// Run the test
testPHPSignature();
?>