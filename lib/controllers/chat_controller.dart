import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/app_snackbar.dart';

class ChatController extends GetxController {
  // Text controller
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // Reactive variables
  var messages = <Map<String, dynamic>>[].obs;
  var isSending = false.obs;
  var isAgentTyping = false.obs;
  var agentStatus = 'Online'.obs;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadChatHistory();
    _startAgentStatusCheck();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void loadChatHistory() {
    // Load existing chat messages (mock data for demo)
    messages.value = [
      {
        'id': '1',
        'text': 'Hello! Welcome to RiDeal Support. How can I help you today?',
        'isUser': false,
        'time': '2:30 PM',
        'status': 'delivered',
      },
      {
        'id': '2',
        'text': 'Hi, I have a question about my earnings calculation.',
        'isUser': true,
        'time': '2:32 PM',
        'status': 'read',
      },
      {
        'id': '3',
        'text': 'I\'d be happy to help you with that! Can you please provide more details about the specific issue with your earnings?',
        'isUser': false,
        'time': '2:33 PM',
        'status': 'delivered',
      },
    ];
    _scrollToBottom();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending.value) return;

    try {
      isSending.value = true;

      // Add user message to chat
      final userMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'isUser': true,
        'time': _getCurrentTime(),
        'status': 'sending',
      };

      messages.add(userMessage);
      messageController.clear();
      _scrollToBottom();

      // Simulate API call to send message
      await Future.delayed(const Duration(milliseconds: 500));

      // Update message status to sent
      final index = messages.indexWhere((msg) => msg['id'] == userMessage['id']);
      if (index != -1) {
        messages[index]['status'] = 'sent';
        messages.refresh();
      }

      // Simulate agent typing
      _simulateAgentResponse(text);

    } catch (e) {
      showErrorSnackBar(
        'Failed to send message: ${e.toString()}',
        title: 'Error',
      );
    } finally {
      isSending.value = false;
    }
  }

  void _simulateAgentResponse(String userMessage) {
    // Show typing indicator
    isAgentTyping.value = true;

    // Simulate agent response after delay
    Future.delayed(const Duration(seconds: 2), () {
      isAgentTyping.value = false;

      String response = _generateAgentResponse(userMessage);

      final agentMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': response,
        'isUser': false,
        'time': _getCurrentTime(),
        'status': 'delivered',
      };

      messages.add(agentMessage);
      _scrollToBottom();

      // Mark user's message as read
      final lastUserMsgIndex = messages.lastIndexWhere((msg) => msg['isUser'] == true);
      if (lastUserMsgIndex != -1) {
        messages[lastUserMsgIndex]['status'] = 'read';
        messages.refresh();
      }
    });
  }

  String _generateAgentResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('earning') || lowerMessage.contains('payment')) {
      return 'I understand you have questions about earnings. Your earnings are calculated based on completed trips, distance, and time. You can view detailed breakdowns in the Trip History section. Is there a specific trip you\'d like me to review?';
    } else if (lowerMessage.contains('trip') || lowerMessage.contains('ride')) {
      return 'For trip-related queries, I can help you with ride history, trip details, or any issues during rides. What specific information do you need?';
    } else if (lowerMessage.contains('problem') || lowerMessage.contains('issue')) {
      return 'I\'m sorry to hear you\'re experiencing an issue. Can you please describe the problem in detail so I can assist you better?';
    } else if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return 'You\'re welcome! Is there anything else I can help you with today?';
    } else {
      return 'Thank you for your message. I\'ve noted your query and will assist you accordingly. Can you provide more details so I can help you better?';
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startAgentStatusCheck() {
    // Simulate agent status updates
    agentStatus.value = 'Online';

    // Randomly update status
    Future.delayed(const Duration(minutes: 2), () {
      if (agentStatus.value == 'Online') {
        agentStatus.value = 'Typically replies in a few minutes';
      }
    });
  }

  Future<void> attachCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        _sendAttachment({
          'type': 'image',
          'path': photo.path,
          'name': photo.name,
        });
      }
    } catch (e) {
      showErrorSnackBar(
        'Failed to capture image: ${e.toString()}',
        title: 'Error',
      );
    }
  }

  Future<void> attachGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        _sendAttachment({
          'type': 'image',
          'path': image.path,
          'name': image.name,
        });
      }
    } catch (e) {
      showErrorSnackBar(
        'Failed to select image: ${e.toString()}',
        title: 'Error',
      );
    }
  }

  Future<void> attachDocument() async {
    // For now, simulate document attachment
    showInfoSnackBar(
      'Document attachment feature will be available soon',
      title: 'Document Attachment',
    );
  }

  void _sendAttachment(Map<String, dynamic> attachment) {
    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': 'Sent an ${attachment['type']}',
      'isUser': true,
      'time': _getCurrentTime(),
      'status': 'sent',
      'attachment': attachment,
    };

    messages.add(message);
    _scrollToBottom();

    // Simulate agent response to attachment
    Future.delayed(const Duration(seconds: 1), () {
      final agentMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': 'Thank you for sharing the ${attachment['type']}. I\'ve received it and will review it to assist you better.',
        'isUser': false,
        'time': _getCurrentTime(),
        'status': 'delivered',
      };

      messages.add(agentMessage);
      _scrollToBottom();
    });
  }

  void clearChat() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              messages.clear();
              Get.back();
              showInfoSnackBar(
                'All messages have been removed',
                title: 'Chat Cleared',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void reportIssue() {
    Get.dialog(
      AlertDialog(
        title: const Text('Report Issue'),
        content: const Text('Would you like to report an issue with this chat or escalate to a supervisor?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              showSuccessSnackBar(
                'Your report has been submitted to our team',
                title: 'Issue Reported',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
            ),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void makeCall() {
    Get.dialog(
      AlertDialog(
        title: const Text('Call Support'),
        content: const Text('Would you like to call our support team directly?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();

              // Launch phone dialer with the support number
              final Uri phoneUri = Uri(scheme: 'tel', path: '06792 451322');

              try {
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  showErrorSnackBar(
                    'Unable to make phone call. Please dial 06792 451322 manually.',
                    title: 'Error',
                  );
                }
              } catch (e) {
                showErrorSnackBar(
                  'Failed to open dialer: ${e.toString()}',
                  title: 'Error',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
            child: const Text('Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void openWhatsApp() {
    Get.dialog(
      AlertDialog(
        title: const Text('WhatsApp Support'),
        content: const Text('Would you like to contact our support team via WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();

              // WhatsApp number and message
              const phoneNumber = '+91 7859815062';
              const message = 'Hello, I need support with my RiDeal driver app.';

              // Create WhatsApp URL
              final Uri whatsappUri = Uri.parse(
                'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}'
              );

              try {
                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                } else {
                  showErrorSnackBar(
                    'WhatsApp is not installed. Please install WhatsApp or contact support at $phoneNumber',
                    title: 'Error',
                  );
                }
              } catch (e) {
                showErrorSnackBar(
                  'Failed to open WhatsApp: ${e.toString()}',
                  title: 'Error',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
            child: const Text('Open WhatsApp', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
