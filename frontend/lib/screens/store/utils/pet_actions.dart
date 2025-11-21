import 'package:flutter/material.dart';

class PetActions {
  static Future<void> updatePetStatus({
    required BuildContext context,
    required dynamic adoption,
    required String status,
    required Function(String) onUpdate,
  }) async {
    try {
      print('Updating pet ${adoption.id} status to: $status');
      await onUpdate(status);
      
      if (context.mounted) {
        final statusText = _getStatusText(status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pet status updated to $statusText'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in updatePetStatus: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'pending':
        return 'Adoption Pending';
      case 'adopted':
        return 'Adopted';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  static void showDeleteConfirmation({
    required BuildContext context,
    required dynamic adoption,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet Listing'),
        content: Text(
          'Are you sure you want to delete ${adoption.petName}\'s adoption listing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static Future<void> deletePet({
    required BuildContext context,
    required Function() onDelete,
  }) async {
    try {
      await onDelete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet listing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete listing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
