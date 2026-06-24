import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/models/ticket.dart';
import '../services/ticket_service.dart';
import '../core/utils/app_snackbar.dart';
import '../core/token_manager.dart';

class SupportController extends GetxController {
  final TicketService _ticketService = TicketService();

  // Reactive variables
  var isLoading = false.obs;
  var supportTickets = <Ticket>[].obs;
  var selectedPriority = 'high'.obs;

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadInitialTickets();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> loadInitialTickets() async {
    try {
      isLoading.value = true;
      supportTickets.value = [];
      
      final tokenManager = Get.find<TokenManager>();
      final driverId = tokenManager.userId.value;
      
      if (driverId != null && driverId.isNotEmpty) {
        final result = await _ticketService.getTickets(driverId);
        if (result['success'] == true) {
          final List<Ticket> tickets = List<Ticket>.from(result['tickets']);
          // Sort by newest first
          tickets.sort((a, b) {
            try {
              return DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt));
            } catch (_) {
              return 0;
            }
          });
          supportTickets.value = tickets;
        } else {
          showErrorSnackBar(result['message'] ?? 'Failed to load tickets');
        }
      }
    } catch (e) {
      print('Error loading initial tickets: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitSupportTicket() async {
    if (titleController.text.trim().isEmpty) {
      showErrorSnackBar(
        'Please enter a ticket title',
        title: 'Error',
      );
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      showErrorSnackBar(
        'Please provide a description',
        title: 'Error',
      );
      return;
    }

    try {
      isLoading.value = true;

      final result = await _ticketService.createTicket(
        ticketTitle: titleController.text.trim(),
        description: descriptionController.text.trim(),
        priority: selectedPriority.value,
      );

      if (result['success']) {
        final ticket = result['ticket'] as Ticket;
        supportTickets.add(ticket);

        // Clear form fields
        titleController.clear();
        descriptionController.clear();
        selectedPriority.value = 'high';

        // Close dialog and show success message
        Get.back();
        showSuccessSnackBar(
          'Support ticket created successfully',
          title: 'Success',
        );
      } else {
        showErrorSnackBar(
          result['message'] ?? 'Failed to create ticket',
          title: 'Error',
        );
      }
    } catch (e) {
      showErrorSnackBar(
        'An unexpected error occurred',
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
