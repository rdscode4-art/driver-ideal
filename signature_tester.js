/**
 * 🧪 STANDALONE SIGNATURE VERIFICATION TESTER
 * Use this to test if your backend generates the correct expected signature
 */

const crypto = require('crypto');

function testRazorpaySignature() {
    console.log('🧪 ════════════════════════════════════════════════════════');
    console.log('🧪         RAZORPAY SIGNATURE VERIFICATION TESTER');
    console.log('🧪 ════════════════════════════════════════════════════════');
    
    // Your actual data from the failed verification
    const testData = {
        orderId: 'order_RpTmsJFWeZ4FOI',
        paymentId: 'pay_RpTnA8xEtptd8c',
        expectedSignature: 'fcb552fb0a7187feefb1f1c6ba2a6b80c1195ed26ed0a537d0b512fad0e22b5c',
        secret: 'C79lUWsMza7uO849xeo0no5c'
    };
    
    console.log('📋 Test Data:');
    console.log('   Order ID:', testData.orderId);
    console.log('   Payment ID:', testData.paymentId);
    console.log('   Expected Signature:', testData.expectedSignature);
    console.log('   Secret Key:', testData.secret.substring(0, 10) + '...');
    console.log('');
    
    // Step 1: Create payload
    const payload = testData.orderId + "|" + testData.paymentId;
    console.log('📦 Payload Formula: order_id + "|" + payment_id');
    console.log('📦 Actual Payload:', payload);
    console.log('');
    
    // Step 2: Generate signature
    const generatedSignature = crypto
        .createHmac('sha256', testData.secret)
        .update(payload)
        .digest('hex');
    
    console.log('🎯 Generated Signature:', generatedSignature);
    console.log('🔄 Expected Signature: ', testData.expectedSignature);
    console.log('');
    
    // Step 3: Compare
    const matches = generatedSignature === testData.expectedSignature;
    console.log('✅ Signatures Match:', matches ? '🎉 YES' : '❌ NO');
    
    if (!matches) {
        console.log('');
        console.log('🔍 DEBUGGING INFO:');
        console.log('   Generated Length:', generatedSignature.length);
        console.log('   Expected Length: ', testData.expectedSignature.length);
        console.log('   Generated (first 20):', generatedSignature.substring(0, 20));
        console.log('   Expected (first 20): ', testData.expectedSignature.substring(0, 20));
    }
    
    console.log('🧪 ════════════════════════════════════════════════════════');
    
    return matches;
}

// Test with different scenarios
function runAllTests() {
    console.log('🚀 Running all signature verification tests...\n');
    
    // Test 1: Your actual data
    console.log('TEST 1: Your Actual Payment Data');
    testRazorpaySignature();
    console.log('\n');
    
    // Test 2: Example from Razorpay docs
    console.log('TEST 2: Razorpay Documentation Example');
    const docExample = {
        orderId: 'order_9A33XWu170gUtm',
        paymentId: 'pay_29QQoUBi66xm2f',
        secret: 'test_secret_key',
        expectedSignature: '0d4e745a1838664ad6c9c9902212a32d627d68e917580f61dd388b01620fe1ad'
    };
    
    const docPayload = docExample.orderId + "|" + docExample.paymentId;
    const docGenerated = crypto
        .createHmac('sha256', docExample.secret)
        .update(docPayload)
        .digest('hex');
    
    console.log('📋 Doc Example:');
    console.log('   Payload:', docPayload);
    console.log('   Generated:', docGenerated);
    console.log('   Expected: ', docExample.expectedSignature);
    console.log('   Match:', docGenerated === docExample.expectedSignature ? '✅' : '❌');
    console.log('');
}

// Run tests
runAllTests();

module.exports = { testRazorpaySignature, runAllTests };