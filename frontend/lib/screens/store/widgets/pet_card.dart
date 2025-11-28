import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';

class PetCard extends StatelessWidget {
  final dynamic adoption;
  final VoidCallback onTap;

  const PetCard({
    super.key,
    required this.adoption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section - Reduced to 60 to give text more room
                Expanded(
                  flex: 60, 
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: adoption.photo != null
                            ? Image.network(
                                adoption.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      Icons.pets,
                                      size: 48,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.5),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.pets,
                                  size: 48,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.5),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer<StoreProvider>(
                          builder: (context, provider, child) {
                            final isFavorite =
                                provider.isPetFavorite(adoption.id);
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                color: isFavorite ? Colors.red : Colors.white,
                                iconSize: 22,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                onPressed: () {
                                  provider.togglePetFavorite(adoption.id);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      // Status badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: adoption.status == 'available'
                                ? Colors.green.withOpacity(0.9)
                                : adoption.status == 'pending'
                                    ? Colors.orange.withOpacity(0.9)
                                    : adoption.status == 'adopted'
                                        ? Colors.red.withOpacity(0.9)
                                        : Colors.grey.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            adoption.status.toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Section - Increased to 40
                Expanded(
                  flex: 40,
                  child: Padding(
                    // Reduced vertical padding slightly
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adoption.petName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Reduced gap from 4 to 2
                        const SizedBox(height: 2),
                        // Compact details row: gender icon/text + age
                        Row(
                          children: [
                            if (adoption.gender != null &&
                                (adoption.gender as String).isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    adoption.gender.toString().toLowerCase() ==
                                            'male'
                                        ? Icons.male
                                        : Icons.female,
                                    size: 12,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    adoption.gender.toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.grey[200]
                                          : const Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            Flexible(
                              child: Text(
                                adoption.ageDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Reduced gap between Gender and Breed from 6 to 2
                        if (adoption.breed != null &&
                            (adoption.breed as String).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            adoption.breed,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        
                        // Pushes the button to the bottom
                        const Spacer(), 
                        
                        SizedBox(
                          width: double.infinity,
                          height: 28,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color.fromRGBO(124, 58, 237, 0.85),
                                  Color.fromRGBO(124, 58, 237, 0.65)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                            ),
                            child: ElevatedButton(
                              onPressed: onTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}