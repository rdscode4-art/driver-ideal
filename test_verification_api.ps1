# 🧪 POWERSHELL TEST FOR RAZORPAY VERIFICATION API

Write-Host "🧪 ════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🧪         TESTING RAZORPAY VERIFICATION API" -ForegroundColor Cyan  
Write-Host "🧪 ════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Your actual payment data
$DRIVER_ID = "6937eb2b09d26c61e7927d20"
$PLAN_ID = "68ede14b0efa19665b81303e"
$PAYMENT_ID = "pay_RpTnA8xEtptd8c"
$ORDER_ID = "order_RpTmsJFWeZ4FOI"
$SIGNATURE = "fcb552fb0a7187feefb1f1c6ba2a6b80c1195ed26ed0a537d0b512fad0e22b5c"

# Your backend URL
$BACKEND_URL = "https://backend.ridealmobility.com/verify-subscription-payment"

Write-Host "📡 Testing with data:" -ForegroundColor Yellow
Write-Host "   Driver ID: $DRIVER_ID" -ForegroundColor White
Write-Host "   Plan ID: $PLAN_ID" -ForegroundColor White
Write-Host "   Payment ID: $PAYMENT_ID" -ForegroundColor White
Write-Host "   Order ID: $ORDER_ID" -ForegroundColor White
Write-Host "   Signature: $SIGNATURE" -ForegroundColor White
Write-Host ""

# Create JSON payload
$JSON_PAYLOAD = @{
    driverId = $DRIVER_ID
    planId = $PLAN_ID
    razorpay_payment_id = $PAYMENT_ID
    razorpay_order_id = $ORDER_ID
    razorpay_signature = $SIGNATURE
} | ConvertTo-Json

Write-Host "📤 Request JSON:" -ForegroundColor Yellow
Write-Host $JSON_PAYLOAD -ForegroundColor White
Write-Host ""

Write-Host "🚀 Sending request to: $BACKEND_URL" -ForegroundColor Green
Write-Host ""

try {
    # Send request
    $response = Invoke-RestMethod -Uri $BACKEND_URL -Method POST -Body $JSON_PAYLOAD -ContentType "application/json" -ErrorAction Stop
    
    Write-Host "✅ Response received:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor White
    
} catch {
    Write-Host "❌ Request failed:" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get response body
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response Body: $responseBody" -ForegroundColor Yellow
        } catch {
            Write-Host "Could not read response body" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "🧪 ════════════════════════════════════════════════════════" -ForegroundColor Cyan