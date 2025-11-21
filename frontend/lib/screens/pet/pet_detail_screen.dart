import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pet/pet_model.dart';
import '../../providers/pet_provider.dart';
import '../../services/pet_service.dart';
import '../../widgets/custom_app_bar.dart';

// Screens for add/edit flows
import 'forms/add_vaccination_screen.dart';
import 'forms/add_medical_record_screen.dart';
import 'forms/edit_pet_screen.dart';

// Widgets
import 'widgets/pet_header.dart';
import 'widgets/pet_info_tab.dart';
import 'widgets/vaccination_tab.dart';
import 'widgets/medical_tab.dart';
import 'widgets/gradient_fab.dart';

class PetDetailScreen extends StatefulWidget {
  final PetModel pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen>
    with SingleTickerProviderStateMixin {
  final PetService _service = PetService();

  late PetModel _pet;
  late TabController _tabController;

  List<VaccinationModel> _vaccinations = [];
  List<MedicalRecordModel> _medicalRecords = [];

  bool _loading = true;
  String? _error;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (_pet.id == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid pet ID';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final v = await _service.getVaccinations(_pet.id!);
      final m = await _service.getMedicalRecords(_pet.id!);
      setState(() {
        _vaccinations = v;
        _medicalRecords = m;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshPetFromProvider() async {
    final provider = context.read<PetProvider>();
    await provider.loadPets();
    final updated = provider.pets.firstWhere(
      (p) => p.id == _pet.id,
      orElse: () => _pet,
    );
    setState(() {
      _pet = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pet Details',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => EditPetScreen(pet: _pet)),
              );
              if (ok == true && mounted) {
                await _refreshPetFromProvider();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pet updated')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Pet'),
                  content:
                      Text('Are you sure you want to delete "${_pet.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                final ok =
                    await context.read<PetProvider>().deletePet(_pet.id!);
                if (ok && mounted) {
                  Navigator.pop(context, true);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete pet')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    PetHeader(pet: _pet),
                    _buildTabBar(),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            PetInfoTab(pet: _pet),
                            VaccinationTab(
                              vaccinations: _vaccinations,
                              onRefresh: _loadAll,
                            ),
                            MedicalTab(
                              medicalRecords: _medicalRecords,
                              onRefresh: _loadAll,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6B46C1),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF6B46C1),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        tabs: const [
          Tab(text: 'Info'),
          Tab(text: 'Vaccinations'),
          Tab(text: 'Medical'),
        ],
      ),
    );
  }

  // FAB changes per tab
  Widget? _buildFab() {
    VoidCallback? onPressed;
    
    if (_currentTabIndex == 1) {
      // Vaccinations tab
      onPressed = () async {
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddVaccinationScreen(petId: _pet.id!),
          ),
        );
        if (ok == true) _loadAll();
      };
    } else if (_currentTabIndex == 2) {
      // Medical tab
      onPressed = () async {
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddMedicalRecordScreen(petId: _pet.id!),
          ),
        );
        if (ok == true) _loadAll();
      };
    }

    return GradientFab(onPressed: onPressed);
  }
}