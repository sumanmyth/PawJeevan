import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/helpers.dart';
import '../ai/breed_detection_screen.dart';
import '../ai/chat_screen.dart' show AIChatScreen;
import '../ai/diet_recommendation_screen.dart';
import '../ai/disease_detection_screen.dart';

class AiTab extends StatelessWidget {
  const AiTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'AI Features',
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
        children: [
          // Header
          Text(
            'AI-Powered Tools',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Smart features to help care for your pets',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // AI Features
          _AIFeatureCard(
            icon: Icons.camera_alt,
            title: 'Breed Detection',
            description: 'Identify your pet\'s breed from a photo',
            accentColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BreedDetectionScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _AIFeatureCard(
            icon: Icons.medical_services,
            title: 'Disease Detection',
            description: 'Check for common pet health issues',
            accentColor: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiseaseDetectionScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _AIFeatureCard(
            icon: Icons.restaurant,
            title: 'Diet Recommendations',
            description: 'Get personalized nutrition advice',
            accentColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DietRecommendationScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _AIFeatureCard(
            icon: Icons.chat,
            title: 'AI Pet Assistant',
            description: 'Chat with our AI pet care expert',
            accentColor: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIChatScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _AIFeatureCard(
            icon: Icons.photo_filter,
            title: 'Photo Enhancer',
            description: 'Enhance your pet photos',
            accentColor: Colors.pink,
            onTap: () {
              Helpers.showInstantSnackBar(
                context,
                const SnackBar(content: Text('Photo Enhancer - Coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AIFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback? onTap;

  const _AIFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor; // Adapts to light/dark
    final onSurfaceColor = theme.colorScheme.onSurface;
    final onSurfaceVariantColor = theme.colorScheme.onSurfaceVariant;
    
    // Create a theme-aware background color with low opacity
    final accentBackgroundColor = accentColor.withOpacity(0.1);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // Subtle shadow
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // The icon container with the colored background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: onSurfaceVariantColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 20, color: onSurfaceVariantColor.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}