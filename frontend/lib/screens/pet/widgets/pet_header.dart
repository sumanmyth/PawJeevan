import 'package:flutter/material.dart';
import '../../../models/pet/pet_model.dart';
import 'full_screen_image.dart';

/// Gradient header section showing pet photo and basic info
class PetHeader extends StatelessWidget {
  final PetModel pet;

  const PetHeader({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color.fromRGBO(124, 58, 237, 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
          bottom: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPetPhoto(context, pet.photo),
            const SizedBox(width: 16),
            Expanded(child: _buildPetInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildPetPhoto(BuildContext context, String? url) {
    return GestureDetector(
        onTap: url != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImage(
                      imageUrl: url,
                      heroTag: 'pet_photo_${pet.id}',
                    ),
                  ),
                );
              }
            : null,
      child: Hero(
        tag: 'pet_photo_${pet.id}',
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7C3AED),
                Color.fromRGBO(124, 58, 237, 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            image: url != null
                ? DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: url == null
              ? const Icon(Icons.pets, size: 45, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _buildPetInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pet.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${pet.breed} • ${pet.petType} • ${pet.gender}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(Icons.cake, '${pet.age} yrs'),
            _buildChip(Icons.monitor_weight, '${pet.weight} kg'),
            if (pet.color != null && pet.color!.isNotEmpty)
              _buildChip(Icons.color_lens, pet.color!),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
