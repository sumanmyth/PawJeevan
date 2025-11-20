import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/store_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'adoption/pet_detail_screen.dart';
import 'adoption/create_adoption_screen.dart';
import 'widgets/store_banner.dart';
import 'widgets/store_tab_selector.dart';
import 'widgets/store_category_menu.dart';
import 'widgets/pet_type_menu.dart';
import 'adoption/all_pets_screen.dart';
import 'adoption/pet_grids.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  final List<String> _categories = ['Adoption', 'Food', 'Toys'];
  String _selectedCategory = 'Adoption';
  late TabController _tabController;
  int _currentTabIndex = 0;
  bool _showBanner = true;
  bool _isCheckingBanner = true;
  final List<Map<String, String>> _petTypes = [
    {'id': 'all', 'label': 'All'},
    {'id': 'dog', 'label': 'Dogs'},
    {'id': 'cat', 'label': 'Cats'},
    {'id': 'bird', 'label': 'Birds'},
    {'id': 'rabbit', 'label': 'Rabbits'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _currentTabIndex = 1;
    _tabController.addListener(_handleTabChange);
    _checkBannerVisibilitySync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<StoreProvider>();
        provider.loadAdoptions(showAllStatuses: true).catchError((error) {
          print('Error loading adoptions: $error');
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      final provider = context.read<StoreProvider>();
      // Clear search when tab changes
      provider.setSearchQuery('');
      if (_tabController.index == 0) {
        provider.loadAdoptions(showAllStatuses: false);
      } else {
        provider.loadAdoptions(showAllStatuses: true);
      }
    }
  }

  void _checkBannerVisibilitySync() {
    SharedPreferences.getInstance().then((prefs) {
      final lastDismissed = prefs.getString('banner_dismissed_date_time');
      
      if (lastDismissed == null) {
        if (mounted) {
          setState(() {
            _showBanner = true;
            _isCheckingBanner = false;
          });
        }
        return;
      }
      
      final lastDismissedTime = DateTime.parse(lastDismissed);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dismissedDate = DateTime(lastDismissedTime.year, lastDismissedTime.month, lastDismissedTime.day);
      
      if (mounted) {
        setState(() {
          _showBanner = today.isAfter(dismissedDate) || 
                        now.difference(lastDismissedTime).inHours >= 4;
          _isCheckingBanner = false;
        });
      }
    });
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('banner_dismissed_date_time', DateTime.now().toIso8601String());
    
    setState(() {
      _showBanner = false;
    });
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    final provider = context.read<StoreProvider>();
    searchController.text = provider.searchQuery;

    // Get category-specific search hint
    String searchHint;
    String dialogTitle;
    switch (_selectedCategory) {
      case 'Adoption':
        searchHint = 'Search by breed, name, age...';
        dialogTitle = 'Search Pets for Adoption';
        break;
      case 'Food':
        searchHint = 'Search by food type, brand, ingredients...';
        dialogTitle = 'Search Pet Food';
        break;
      case 'Toys':
        searchHint = 'Search by toy type, material, size...';
        dialogTitle = 'Search Pet Toys';
        break;
      default:
        searchHint = 'Search...';
        dialogTitle = 'Search';
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900.withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dialogTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B46C1)),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF6B46C1),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (value) {
                    provider.setSearchQuery(value);
                    provider.searchAdoptions();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        searchController.clear();
                        provider.setSearchQuery('');
                        provider.searchAdoptions();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6B46C1),
                              Color(0xFF9F7AEA),
                              Color(0xFFB794F6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            provider.setSearchQuery(searchController.text);
                            provider.searchAdoptions();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Search',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Store',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Pets',
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => storeProvider.loadAdoptions(showAllStatuses: _currentTabIndex == 1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isCheckingBanner && _showBanner)
                    StoreBanner(
                      onDismiss: _dismissBanner,
                      onAdoptClick: () {
                        setState(() {
                          _selectedCategory = 'Adoption';
                          _tabController.animateTo(0);
                          _currentTabIndex = 0;
                        });
                        context.read<StoreProvider>().loadAdoptions(showAllStatuses: false);
                      },
                    ),
                  
                  const SizedBox(height: 16),
                  
                  StoreCategoryMenu(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      // Clear search when category changes
                      context.read<StoreProvider>().setSearchQuery('');
                      context.read<StoreProvider>().searchAdoptions();
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_selectedCategory == 'Adoption') ...[
                    StoreTabSelector(tabController: _tabController),
                    const SizedBox(height: 16),
                    if (_currentTabIndex == 0) ...[
                      _buildSectionHeader('Find Your New Best Friend'),
                      const SizedBox(height: 16),
                      PetTypeMenu(provider: storeProvider, petTypes: _petTypes),
                      const SizedBox(height: 16),
                      PetGrids.buildAdoptionGrid(
                        context: context,
                        provider: storeProvider,
                        onPetTap: (id) => _navigateToPetDetail(id),
                      ),
                    ] else ...[
                      _buildSectionHeader('My Pets for Adoption'),
                      const SizedBox(height: 16),
                      PetGrids.buildMyPetsGrid(
                        context: context,
                        provider: storeProvider,
                        onPetTap: (id) => _navigateToPetDetail(id),
                        onPetOptions: (adoption) => _showPetOptions(adoption),
                      ),
                    ],
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('Coming Soon!', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedCategory == 'Adoption'
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA), Color(0xFFB794F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B46C1).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToCreateAdoption(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Pet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDiscoverTab = _currentTabIndex == 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () => _showAllPets(isDiscoverTab),
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  void _showPetOptions(adoption) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Manage ${adoption.petName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF6B46C1)),
              title: const Text('Edit Pet Details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditAdoption(adoption);
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Change Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.green),
              title: const Text('Available'),
              subtitle: const Text('Pet is available for adoption'),
              trailing: adoption.status == 'available'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updatePetStatus(adoption, 'available');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: const Text('Adoption Pending'),
              subtitle: const Text('Someone is interested in adopting'),
              trailing: adoption.status == 'pending'
                  ? const Icon(Icons.check_circle, color: Colors.orange)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updatePetStatus(adoption, 'pending');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Adopted'),
              subtitle: const Text('Pet has been successfully adopted'),
              trailing: adoption.status == 'adopted'
                  ? const Icon(Icons.check_circle, color: Colors.red)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updatePetStatus(adoption, 'adopted');
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('Closed'),
              subtitle: const Text('Listing is no longer active'),
              trailing: adoption.status == 'closed'
                  ? const Icon(Icons.check_circle, color: Colors.grey)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updatePetStatus(adoption, 'closed');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Listing'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(adoption);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditAdoption(adoption) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAdoptionScreen(adoption: adoption),
      ),
    );
    
    if (result == true && mounted) {
      context.read<StoreProvider>().loadAdoptions(showAllStatuses: _currentTabIndex == 1);
    }
  }

  Future<void> _updatePetStatus(adoption, String status) async {
    final provider = context.read<StoreProvider>();
    
    try {
      print('Updating pet ${adoption.id} status to: $status');
      final success = await provider.updateAdoptionStatus(adoption.id, status);
      
      if (!success) {
        throw Exception(provider.error ?? 'Unknown error updating status');
      }
      
      await provider.loadAdoptions(showAllStatuses: true);
      
      if (mounted) {
        final statusText = status == 'available' 
            ? 'Available' 
            : status == 'pending' 
              ? 'Adoption Pending' 
              : status == 'adopted' 
                ? 'Adopted' 
                : 'Closed';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pet status updated to $statusText'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in _updatePetStatus: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(adoption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet Listing'),
        content: Text('Are you sure you want to delete ${adoption.petName}\'s adoption listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePet(adoption);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePet(adoption) async {
    final provider = context.read<StoreProvider>();
    
    try {
      await provider.deleteAdoption(adoption.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet listing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete listing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPetDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(adoptionId: id),
      ),
    );
  }

  Future<void> _navigateToCreateAdoption() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateAdoptionScreen(),
      ),
    );
    
    if (result == true && mounted) {
      context.read<StoreProvider>().loadAdoptions(showAllStatuses: _currentTabIndex == 1);
    }
  }

  void _showAllPets(bool isDiscoverTab) {
    final provider = context.read<StoreProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    
    List<dynamic> pets;
    String title;
    
    if (isDiscoverTab) {
      pets = currentUserId != null
          ? provider.adoptions
              .where((adoption) => adoption.poster != currentUserId)
              .toList()
          : provider.adoptions;
      title = 'All Available Pets';
    } else {
      pets = provider.adoptions
          .where((adoption) => adoption.poster == currentUserId)
          .toList();
      title = 'All My Pets';
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllPetsScreen(
          pets: pets,
          title: title,
          isMyPets: !isDiscoverTab,
        ),
      ),
    );
  }
}
