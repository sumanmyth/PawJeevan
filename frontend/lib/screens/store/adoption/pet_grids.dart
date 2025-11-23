import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/pet_card.dart';
import '../widgets/my_pet_card.dart';

class PetGrids {
  static Widget buildAdoptionGrid({
    required BuildContext context,
    required StoreProvider provider,
    required Function(int) onPetTap,
  }) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    
    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.error != null) {
      return _buildErrorWidget(theme, provider);
    }

    // Apply location filter from provider using the current user's profile location
    final allFiltered = provider.filteredAdoptionsForLocation(authProvider.user?.location);
    final discoverPets = currentUserId != null
      ? allFiltered.where((adoption) => adoption.poster != currentUserId).toList()
      : allFiltered;

    if (discoverPets.isEmpty) {
      return _buildEmptyState(theme, 'No pets available for adoption', 'Check back later for new pets!');
    }

    return _buildGrid(discoverPets, onPetTap);
  }

  static Widget buildMyPetsGrid({
    required BuildContext context,
    required StoreProvider provider,
    required Function(int) onPetTap,
    required Function(dynamic) onPetOptions,
  }) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.id;

    if (currentUserId == null) {
      return _buildEmptyState(theme, 'Please login to view your pets', '');
    }

    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final myPets = provider.adoptions
        .where((adoption) => adoption.poster == currentUserId)
        .toList();

    if (myPets.isEmpty) {
      return _buildEmptyState(
        theme,
        'You haven\'t posted any pets for adoption yet',
        'Tap the "Add Pet" button to list a pet!',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          final aspectRatio = constraints.maxWidth > 600 ? 0.75 : 0.72;
          
          return GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: myPets.length,
            itemBuilder: (context, index) {
              final adoption = myPets[index];
              return MyPetCard(
                adoption: adoption,
                onTap: () => onPetTap(adoption.id),
                onLongPress: () => onPetOptions(adoption),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _buildGrid(List<dynamic> pets, Function(int) onPetTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          final aspectRatio = constraints.maxWidth > 600 ? 0.75 : 0.72;
          
          return GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final adoption = pets[index];
              return PetCard(
                adoption: adoption,
                onTap: () => onPetTap(adoption.id),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _buildErrorWidget(ThemeData theme, StoreProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load adoptions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please make sure the backend server is running',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadAdoptions(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
