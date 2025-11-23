import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../utils/helpers.dart';
import '../../../models/pet/adoption_listing_model.dart';
import '../../../services/store_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../pet/widgets/full_screen_image.dart';
import '../../../providers/community_provider.dart';
import '../../profile/user_profile_screen.dart';
import '../../../providers/store_provider.dart';

class PetDetailScreen extends StatefulWidget {
  final int adoptionId;

  const PetDetailScreen({super.key, required this.adoptionId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final StoreService _storeService = StoreService();
  AdoptionListing? _adoption;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdoption();
  }

  Future<void> _loadAdoption() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adoption = await _storeService.fetchAdoptionById(widget.adoptionId);
      setState(() {
        _adoption = adoption;
        _isLoading = false;
      });
      // Prefetch poster user data so avatar loads immediately
      if (adoption != null) {
        // Use provider to fetch and cache user info asynchronously
        try {
          final community = context.read<CommunityProvider>();
          community.getUser(adoption.poster);
        } catch (_) {
          // ignore errors; provider may not be available in some contexts
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Removed unused 'topPadding' variable here
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'Pet Details', showBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAdoption,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _adoption == null
                  ? const Center(child: Text('Pet not found'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final adoption = _adoption!;
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.only(top: topPadding + 16, bottom: 16, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet Image
          if (adoption.photo != null)
            Padding(
              padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImage(
                          imageUrl: adoption.photo!,
                          title: adoption.petName,
                          heroTag: 'pet_photo_${adoption.id}',
                        ),
                      ),
                    );
                  },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      adoption.photo!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.pets, size: 64),
                        );
                      },
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.pets, size: 64),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        adoption.petName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: adoption.status == 'available'
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        adoption.status.toUpperCase(),
                        style: TextStyle(
                          color: adoption.status == 'available'
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  adoption.title,
                  style: theme.textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                // Quick Info
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.pets,
                      adoption.petTypeDisplay,
                      theme,
                    ),
                    _buildInfoChip(
                      Icons.cake,
                      adoption.ageDisplay,
                      theme,
                    ),
                    _buildInfoChip(
                      adoption.gender == 'male' ? Icons.male : Icons.female,
                      adoption.gender.toUpperCase(),
                      theme,
                    ),
                    if (adoption.breed.isNotEmpty)
                      _buildInfoChip(
                        Icons.label,
                        adoption.breed,
                        theme,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                _buildSection('About ${adoption.petName}', adoption.description),

                const SizedBox(height: 16),

                // Health Status
                _buildSection('Health Status', adoption.healthStatus),

                const SizedBox(height: 16),

                // Vaccination Status
                _buildSection('Vaccination Status', adoption.vaccinationStatus),

                const SizedBox(height: 16),

                // Neutered Status
                _buildInfoRow(
                  'Neutered/Spayed',
                  adoption.isNeutered ? 'Yes' : 'No',
                ),

                const SizedBox(height: 24),

                // Contact Information
                Text(
                  'Contact Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildPosterRow(adoption),
                _buildContactRow(Icons.location_on, 'Location', adoption.location),
                _buildContactRow(Icons.phone, 'Phone', adoption.contactPhone),
                _buildContactRow(Icons.email, 'Email', adoption.contactEmail),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final phoneNumber = adoption.contactPhone;
                          final uri = Uri.parse('tel:$phoneNumber');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            // FIXED: Use 'mounted' (State property) instead of 'context.mounted'
                            if (mounted) {
                              Helpers.showInstantSnackBar(
                                context,
                                const SnackBar(
                                  content: Text('Could not open phone dialer'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Contact'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Consumer<StoreProvider>(
                      builder: (context, provider, child) {
                        final isFavorite = provider.isPetFavorite(adoption.id);
                        return ElevatedButton.icon(
                          onPressed: () {
                            provider.togglePetFavorite(adoption.id);
                            Helpers.showInstantSnackBar(
                              context,
                              SnackBar(
                                content: Text(
                                  isFavorite
                                      ? 'Removed from favorites'
                                      : 'Added to favorites!',
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                          ),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFavorite
                              ? const Color(0xFF7C3AED)
                              : Colors.white,
                            foregroundColor: isFavorite
                              ? Colors.white
                              : const Color(0xFF7C3AED),
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ThemeData theme) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: const Color(0xFFE9D8FD),
      labelStyle: const TextStyle(
        color: Color(0xFF7C3AED),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterRow(AdoptionListing adoption) {
    final community = context.watch<CommunityProvider>();
    final user = community.user(adoption.poster);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.person, size: 20, color: Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(userId: adoption.poster),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            adoption.posterUsername.isNotEmpty
                                ? adoption.posterUsername[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Posted by',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          adoption.posterUsername,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

