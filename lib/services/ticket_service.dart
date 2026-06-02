import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../data/models/ticket.dart';
import '../core/storage_helper.dart';
import '../core/utils/app_snackbar.dart';

class TicketService {
  static const String _baseUrl = 'https://backend.ridealmobility.com/api/driver';
  static const String _defaultToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YWMwMjk0YWRjYzQwNTgwYTliMTBkNCIsInJvbGUiOiJkcml2ZXIiLCJpYXQiOjE3NTYxMTc1ODIsImV4cCI6MTc1ODcwOTU4Mn0.-_6pWxaQdQiU8q46TGfuyEhWSTfdWlyadV6BMpwkl7c';

  Future<Map<String, dynamic>> createTicket({
    required String ticketTitle,
    required String description,
    required String priority,
  }) async {
    try {
      // Get auth token from storage
      final token = await StorageHelper.getAuthToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/driver/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'ticketTitle': ticketTitle,
          'description': description,
          'priority': priority,
        }),
      );

      print('Ticket API Response Status: ${response.statusCode}');
      print('Ticket API Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['ticket'] != null) {
            return {
              'success': true,
              'message': 'Ticket created successfully',
              'ticket': Ticket(
                id: data['ticket']['_id'] ?? '',
                userId: data['ticket']['userId'] ?? '',
                userType: data['ticket']['userType'] ?? 'Driver',
                status: data['ticket']['status'] ?? 'open',
                createdAt: data['ticket']['createdAt'] ?? DateTime.now().toIso8601String(),
                ticketTitle: ticketTitle,
                description: description,
                priority: priority,
              ),
            };
          } else {
            return {
              'success': false,
              'message': data['message'] ?? 'Failed to create ticket',
            };
          }
        } catch (e) {
          print('Error parsing ticket response: $e');
          return {
            'success': false,
            'message': 'Invalid response format from server',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Access denied. You do not have permission to create tickets.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create ticket. Please try again.',
        };
      }
    } catch (e) {
      print('Network error creating ticket: $e');
      showErrorSnackBar('Network error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  Future<Map<String, dynamic>> getTickets() async {
    try {
      final token = await StorageHelper.getAuthToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/tickets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'tickets': data['tickets'] ?? [],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to fetch tickets',
      };
    } catch (e) {
      print('Network error fetching tickets: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }
}
