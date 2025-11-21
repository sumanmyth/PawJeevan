import 'package:flutter/material.dart';
import '../../../models/pet/pet_model.dart';

/// Info tab displaying pet details with gradient icon containers
class PetInfoTab extends StatelessWidget {
  final PetModel pet;

  const PetInfoTab({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(context, Icons.pets, 'Name', pet.name),
        _buildInfoCard(context, Icons.category, 'Species', pet.petType),
        _buildInfoCard(context, Icons.stars, 'Breed', pet.breed),
        _buildInfoCard(context, Icons.wc, 'Gender', pet.gender),
        _buildInfoCard(context, Icons.cake, 'Age', '${pet.age} years'),
        _buildInfoCard(context, Icons.monitor_weight, 'Weight', '${pet.weight} kg'),
        if (pet.color != null && pet.color!.isNotEmpty)
          _buildInfoCard(context, Icons.color_lens, 'Color', pet.color!),
        if (pet.medicalNotes != null && pet.medicalNotes!.isNotEmpty)
          _buildInfoCard(context, Icons.medical_information, 'Medical Notes', pet.medicalNotes!),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[200]
                        : const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
