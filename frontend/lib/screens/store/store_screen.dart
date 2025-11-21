import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'adoption/pet_detail_screen.dart';
import 'adoption/create_adoption_screen.dart';
import 'adoption/all_pets_screen.dart';
import 'adoption/pet_grids.dart';
import 'widgets/store_banner.dart';
import 'widgets/store_tab_selector.dart';
import 'widgets/store_category_menu.dart';
import 'widgets/pet_type_menu.dart';
import 'dialogs/search_dialog.dart';
import 'dialogs/manage_pet_modal.dart';
import 'utils/banner_manager.dart';
import 'utils/pet_actions.dart';

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
        // Discover tab - keep pet type filter as is
        provider.loadAdoptions(showAllStatuses: false);
      } else {
        // My Pets tab - reset pet type filter to 'all'
        provider.setSelectedPetType('all', skipReload: true);
        provider.loadAdoptions(showAllStatuses: true);
      }
    }
  }

  void _checkBannerVisibilitySync() {
    BannerManager.shouldShowBanner().then((shouldShow) {
      if (mounted) {
        setState(() {
          _showBanner = shouldShow;
          _isCheckingBanner = false;
        });
      }
    });
  }

  Future<void> _dismissBanner() async {
    await BannerManager.dismissBanner();
    setState(() {
      _showBanner = false;
    });
  }

  void _showSearchDialog() {
    SearchDialog.show(
      context: context,
      selectedCategory: _selectedCategory,
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
                      // Pet type filter only for Discover tab
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
                      // No pet type filter for My Pets tab
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
    ManagePetModal.show(
      context: context,
      adoption: adoption,
      onEdit: () => _navigateToEditAdoption(adoption),
      onStatusChange: (status) => _updatePetStatus(adoption, status),
      onDelete: () => _confirmDelete(adoption),
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
    
    await PetActions.updatePetStatus(
      context: context,
      adoption: adoption,
      status: status,
      onUpdate: (newStatus) async {
        final success = await provider.updateAdoptionStatus(adoption.id, newStatus);
        if (!success) {
          throw Exception(provider.error ?? 'Unknown error updating status');
        }
        await provider.loadAdoptions(showAllStatuses: true);
      },
    );
  }

  void _confirmDelete(adoption) {
    PetActions.showDeleteConfirmation(
      context: context,
      adoption: adoption,
      onConfirm: () => _deletePet(adoption),
    );
  }

  Future<void> _deletePet(adoption) async {
    final provider = context.read<StoreProvider>();
    
    await PetActions.deletePet(
      context: context,
      onDelete: () => provider.deleteAdoption(adoption.id),
    );
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
