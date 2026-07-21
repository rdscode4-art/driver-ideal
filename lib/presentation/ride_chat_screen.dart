import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/token_manager.dart';

class RideChatScreen extends StatefulWidget {
  final String rideId;
  final String receiverId;
  
  const RideChatScreen({
    super.key,
    required this.rideId,
    required this.receiverId,
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TokenManager _tokenManager = TokenManager.instance;
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _tokenManager.userId.value;
    _fetchChatHistory();
    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchChatHistory(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchChatHistory({bool isPolling = false}) async {
    try {
      final token = await _tokenManager.getCurrentToken();
      final url = Uri.parse('https://backend.ridealmobility.com/chat/history?rideId=${widget.rideId}');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Sometimes APIs return success: true, sometimes they don't. We just check if history exists.
        if (data['history'] != null) {
          final newMessages = data['history'];
          // Only update and scroll if new messages arrived
          if (newMessages.length != _messages.length) {
            setState(() {
              _messages = newMessages;
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      print('Error fetching chat history: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    try {
      final token = await _tokenManager.getCurrentToken();
      final url = Uri.parse('https://backend.ridealmobility.com/chat/send');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'rideId': widget.rideId,
          'receiverId': widget.receiverId,
          'message': text,
        }),
      );

      if (response.statusCode == 201) {
        // Fetch immediately after sending to get the new message
        _fetchChatHistory();
      } else {
        print('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Rider', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black87))
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet. Start chatting!', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == _currentUserId;
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.black87 : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isMe ? const Radius.circular(4) : null,
                                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                                ),
                              ),
                              child: Text(
                                msg['message'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
