import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pet_model.dart';
import '../../providers/pet_provider.dart';
import '../../services/pet_service.dart';
import '../../widgets/custom_app_bar.dart';

// Screens for add/edit flows
import 'add_vaccination_screen.dart';
import 'add_medical_record_screen.dart';
import 'edit_pet_screen.dart';
import 'edit_vaccination_screen.dart';
import 'edit_medical_record_screen.dart';

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

  String _fmtDate(DateTime d) => d.toIso8601String().split('T')[0];

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
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _petPhoto(_pet.photo),
                          const SizedBox(width: 16),
                          Expanded(child: _petHeaderInfo()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          tabs: const [
                            Tab(text: 'Info'),
                            Tab(text: 'Vaccinations'),
                            Tab(text: 'Medical'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _infoTab(),
                          _vaccinationTab(),
                          _medicalTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _buildFab(),
    );
  }

  // Header Widgets
  Widget _petPhoto(String? url) {
    return Container(
      width: 90,
      height: 90,
        decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        image: url != null
            ? DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: url == null
          ? Icon(Icons.pets, size: 40, color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }

  Widget _petHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _pet.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_pet.breed} • ${_pet.petType} • ${_pet.gender}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(Icons.cake, '${_pet.age} yrs'),
            _chip(Icons.monitor_weight, '${_pet.weight} kg'),
            if (_pet.color != null && _pet.color!.isNotEmpty)
              _chip(Icons.color_lens, _pet.color!),
          ],
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // Tabs

  Widget _infoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _kv('Name', _pet.name),
        _kv('Species', _pet.petType),
        _kv('Breed', _pet.breed),
        _kv('Gender', _pet.gender),
        _kv('Age', '${_pet.age} years'),
        _kv('Weight', '${_pet.weight} kg'),
        if (_pet.color != null && _pet.color!.isNotEmpty)
          _kv('Color', _pet.color!),
        if (_pet.medicalNotes != null && _pet.medicalNotes!.isNotEmpty)
          _kv('Medical Notes', _pet.medicalNotes!),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          k,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(v),
      ),
    );
  }

  Widget _vaccinationTab() {
    if (_vaccinations.isEmpty) {
      return _empty(
        title: 'No vaccinations yet',
        subtitle: 'Tap + to add a vaccination record',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vaccinations.length,
        itemBuilder: (context, i) {
          final v = _vaccinations[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.vaccines, color: Theme.of(context).colorScheme.primary),
              title: Text(v.vaccineName),
              subtitle: Text(
                'Date: ${_fmtDate(v.vaccinationDate)}'
                '${v.nextDueDate != null ? '\nNext due: ${_fmtDate(v.nextDueDate!)}' : ''}'
                '${v.veterinarian != null && v.veterinarian!.isNotEmpty ? '\nVet: ${v.veterinarian}' : ''}'
                '${v.notes != null && v.notes!.isNotEmpty ? '\nNotes: ${v.notes}' : ''}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditVaccinationScreen(vaccination: v),
                      ),
                    );
                    if (ok == true) _loadAll();
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Vaccination'),
                        content: Text('Delete "${v.vaccineName}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _service.deleteVaccination(v.id!);
                      _loadAll();
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _medicalTab() {
    if (_medicalRecords.isEmpty) {
      return _empty(
        title: 'No medical records yet',
        subtitle: 'Tap + to add a medical record',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicalRecords.length,
        itemBuilder: (context, i) {
          final m = _medicalRecords[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.purple),
              title: Text('${m.recordType.toUpperCase()} • ${m.title}'),
              subtitle: Text(
                'Date: ${_fmtDate(m.date)}'
                '${m.veterinarian != null && m.veterinarian!.isNotEmpty ? '\nVet: ${m.veterinarian}' : ''}'
                '${m.cost != null ? '\nCost: ${m.cost}' : ''}'
                '${m.description.isNotEmpty ? '\n${m.description}' : ''}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditMedicalRecordScreen(record: m),
                      ),
                    );
                    if (ok == true) _loadAll();
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Medical Record'),
                        content: Text('Delete "${m.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _service.deleteMedicalRecord(m.id!);
                      _loadAll();
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // FAB changes per tab
  Widget? _buildFab() {
    if (_currentTabIndex == 1) {
      // Vaccinations tab
      return FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddVaccinationScreen(petId: _pet.id!),
            ),
          );
          if (ok == true) _loadAll();
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      );
    } else if (_currentTabIndex == 2) {
      // Medical tab
      return FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddMedicalRecordScreen(petId: _pet.id!),
            ),
          );
          if (ok == true) _loadAll();
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
}