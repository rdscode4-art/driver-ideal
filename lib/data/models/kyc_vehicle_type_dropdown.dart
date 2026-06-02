// lib/presentation/widgets/kyc_vehicle_type_dropdown.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/kyc_controller.dart';

class KycVehicleTypeDropdown extends StatelessWidget {
  final KYCController controller;

  const KycVehicleTypeDropdown({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading state
      if (controller.isLoadingVehicleTypes) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading vehicle types...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      // Get vehicle types
      final vehicleTypes = controller.vehicleTypes;

      // Show error state with retry
      if (vehicleTypes.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.red.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to load vehicle types',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.red),
                onPressed: () => controller.refreshVehicleTypes(),
                tooltip: 'Retry',
              ),
            ],
          ),
        );
      }

      // Ensure selected type exists in the list
      if (!vehicleTypes.contains(controller.selectedVehicleType.value)) {
        controller.selectedVehicleType.value = vehicleTypes.first;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              color: Colors.white,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: controller.selectedVehicleType.value,
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'Select vehicle type',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              items: vehicleTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Row(
                    children: [
                      // Show vehicle image if available
                      if (controller.vehicleTypeController.getVehicleImage(type) != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image.network(
                            controller.vehicleTypeController.getVehicleImage(type)!,
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.directions_car, size: 28),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.directions_car, size: 28),
                        ),
                      Text(
                        controller.getVehicleTypeDisplayName(type),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: controller.canEditDocuments
                  ? (String? newValue) {
                      if (newValue != null) {
                        controller.selectedVehicleType.value = newValue;
                      }
                    }
                  : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a vehicle type';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          // Show fare information if available
          if (controller.vehicleTypeController.getFareRate(
                  controller.selectedVehicleType.value) !=
              null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFareInfo(controller.vehicleTypeController.getFareRate(
                          controller.selectedVehicleType.value)!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  String _getFareInfo(Map<String, dynamic> fareRate) {
    final perKm = fareRate['perKmRate']?.toString() ?? 'N/A';
    final minFare = fareRate['minFare']?.toString() ?? 'N/A';
    return 'Rate: ₹$perKm/km • Min Fare: ₹$minFare';
  }
}