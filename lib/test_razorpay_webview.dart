// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class TestRazorpayWebView extends StatefulWidget {
//   const TestRazorpayWebView({super.key});

//   @override
//   State<TestRazorpayWebView> createState() => _TestRazorpayWebViewState();
// }

// class _TestRazorpayWebViewState extends State<TestRazorpayWebView> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//   String _result = '';

//   @override
//   void initState() {
//     super.initState();
//     _initializeWebView();
//   }

//   void _initializeWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             print('🌐 Page started loading: $url');
//           },
//           onPageFinished: (String url) {
//             setState(() {
//               _isLoading = false;
//             });
//             print('✅ Page finished loading: $url');
//           },
//           onWebResourceError: (WebResourceError error) {
//             print('❌ Web resource error: ${error.description}');
//             setState(() {
//               _result = 'Error: ${error.description}';
//             });
//           },
//         ),
//       )
//       ..addJavaScriptChannel(
//         'TestHandler',
//         onMessageReceived: (JavaScriptMessage message) {
//           print('📨 Message from WebView: ${message.message}');
//           setState(() {
//             _result = 'Success: ${message.message}';
//           });
//         },
//       )
//       ..loadRequest(Uri.parse('data:text/html;base64,${_getTestHTML()}'));
//   }

//   String _getTestHTML() {
//     final html = '''
//     <!DOCTYPE html>
//     <html>
//     <head>
//       <meta name="viewport" content="width=device-width, initial-scale=1.0">
//       <title>Razorpay Test</title>
//       <style>
//         body {
//           font-family: Arial, sans-serif;
//           padding: 20px;
//           text-align: center;
//         }
//         .status { margin: 20px 0; }
//         .success { color: green; }
//         .error { color: red; }
//         button {
//           background: #667eea;
//           color: white;
//           border: none;
//           padding: 10px 20px;
//           border-radius: 5px;
//           font-size: 16px;
//         }
//       </style>
//     </head>
//     <body>
//       <h2>Razorpay WebView Test</h2>
//       <div id="status" class="status">Loading Razorpay script...</div>
//       <button onclick="testRazorpay()">Test Razorpay</button>
      
//       <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
//       <script>
//         window.addEventListener('load', function() {
//           try {
//             if (typeof Razorpay !== 'undefined') {
//               document.getElementById('status').innerHTML = '<span class="success">✅ Razorpay script loaded successfully!</span>';
//               TestHandler.postMessage('Razorpay script loaded');
//             } else {
//               document.getElementById('status').innerHTML = '<span class="error">❌ Razorpay script failed to load</span>';
//               TestHandler.postMessage('Razorpay script failed');
//             }
//           } catch (e) {
//             document.getElementById('status').innerHTML = '<span class="error">❌ Error: ' + e.message + '</span>';
//             TestHandler.postMessage('Error: ' + e.message);
//           }
//         });
        
//         function testRazorpay() {
//           try {
//             var options = {
//               "key": "rzp_test_RnX4Oatt9zSiqS",
//               "amount": 100,
//               "currency": "INR",
//               "name": "Test Payment",
//               "description": "Test Description",
//               "order_id": "order_test123",
//               "prefill": {
//                 "contact": "9999999999",
//                 "email": "test@example.com"
//               },
//               "theme": {
//                 "color": "#667eea"
//               },
//               "handler": function (response) {
//                 TestHandler.postMessage('Payment Success: ' + JSON.stringify(response));
//               },
//               "modal": {
//                 "ondismiss": function() {
//                   TestHandler.postMessage('Payment Cancelled');
//                 }
//               }
//             };
            
//             var rzp = new Razorpay(options);
            
//             rzp.on('payment.failed', function (response) {
//               TestHandler.postMessage('Payment Failed: ' + JSON.stringify(response));
//             });
            
//             rzp.open();
//             TestHandler.postMessage('Razorpay checkout opened');
            
//           } catch (e) {
//             TestHandler.postMessage('Test Error: ' + e.message);
//           }
//         }
//       </script>
//     </body>
//     </html>
//     ''';

//     return base64Encode(utf8.encode(html));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Razorpay WebView Test'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           if (_result.isNotEmpty)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               color: _result.startsWith('Success')
//                   ? Colors.green[100]
//                   : Colors.red[100],
//               child: Text(
//                 _result,
//                 style: TextStyle(
//                   color: _result.startsWith('Success')
//                       ? Colors.green[800]
//                       : Colors.red[800],
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           Expanded(
//             child: Stack(
//               children: [
//                 WebViewWidget(controller: _controller),
//                 if (_isLoading)
//                   const Center(child: CircularProgressIndicator()),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
