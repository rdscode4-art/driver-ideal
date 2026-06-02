#!/bin/bash

# 🧪 CURL TEST FOR RAZORPAY VERIFICATION API

echo "🧪 ════════════════════════════════════════════════════════"
echo "🧪         TESTING RAZORPAY VERIFICATION API"
echo "🧪 ════════════════════════════════════════════════════════"

# Your actual payment data
DRIVER_ID="6937eb2b09d26c61e7927d20"
PLAN_ID="68ede14b0efa19665b81303e"
PAYMENT_ID="pay_RpTnA8xEtptd8c"
ORDER_ID="order_RpTmsJFWeZ4FOI"
SIGNATURE="fcb552fb0a7187feefb1f1c6ba2a6b80c1195ed26ed0a537d0b512fad0e22b5c"

# Your backend URL
BACKEND_URL="https://backend.ridealmobility.com/verify-subscription-payment"

echo "📡 Testing with data:"
echo "   Driver ID: $DRIVER_ID"
echo "   Plan ID: $PLAN_ID"
echo "   Payment ID: $PAYMENT_ID"
echo "   Order ID: $ORDER_ID"
echo "   Signature: $SIGNATURE"
echo ""

# Create JSON payload
JSON_PAYLOAD="{
  \"driverId\": \"$DRIVER_ID\",
  \"planId\": \"$PLAN_ID\",
  \"razorpay_payment_id\": \"$PAYMENT_ID\",
  \"razorpay_order_id\": \"$ORDER_ID\",
  \"razorpay_signature\": \"$SIGNATURE\"
}"

echo "📤 Request JSON:"
echo "$JSON_PAYLOAD"
echo ""

echo "🚀 Sending request to: $BACKEND_URL"
echo ""

# Send request
curl -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$JSON_PAYLOAD" \
  -v

echo ""
echo "🧪 ════════════════════════════════════════════════════════"