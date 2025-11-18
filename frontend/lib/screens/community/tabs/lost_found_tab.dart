import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../models/lost_found_model.dart';
import '../lost_found/lost_found_detail_screen.dart';
import '../lost_found/edit_lost_found_screen.dart';

class LostFoundTab extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshCallbackRegistered;
  
  const LostFoundTab({super.key, this.onRefreshCallbackRegistered});

  @override
  State<LostFoundTab> createState() => _LostFoundTabState();
}

class _LostFoundTabState extends State<LostFoundTab> with SingleTickerProviderStateMixin {
  late Future<List<LostFoundReport>> _reportsFuture;
  int? _currentUserId;
  late TabController _tabController;
  int _currentTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchExpanded = false;
  bool _showTabs = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
          _reportsFuture = _fetchReportsWithDebug();
        });
      }
    });
    _loadCurrentUser();
    _reportsFuture = _fetchReportsWithDebug();
    
    // Register the refresh callback with parent
    widget.onRefreshCallbackRegistered?.call(refreshReports);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final direction = _scrollController.position.userScrollDirection;
      
      // Hide tabs when scrolling down, show when scrolling up
      if (direction == ScrollDirection.reverse && _showTabs) {
        setState(() {
          _showTabs = false;
        });
      } else if (direction == ScrollDirection.forward && !_showTabs) {
        setState(() {
          _showTabs = true;
        });
      }
    }
  }

  // Public method to refresh reports from external calls
  void refreshReports() {
    setState(() {
      _reportsFuture = _fetchReportsWithDebug();
    });
  }

  // Manual refresh method for pull-to-refresh
  Future<void> _refreshReports() async {
    setState(() {
      _reportsFuture = _fetchReportsWithDebug();
    });
    await _reportsFuture;
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<List<LostFoundReport>> _fetchReportsWithDebug() async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    try {
      // For "My Reports" tab, fetch all statuses by passing empty status filter
      // For others, only fetch active reports
      final queryParams = <String, dynamic>{};
      if (_currentTab == 0) {
        // Pass status parameter with empty value to get all statuses
        queryParams['status'] = '';
      }
      // For other tabs, don't pass status parameter, let backend default to active
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.lostFound}',
        queryParameters: queryParams.isEmpty ? null : queryParams,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<LostFoundReport> allReports = [];
        
        if (data is List) {
          allReports = data.map((json) => LostFoundReport.fromJson(json)).toList();
        } else if (data is Map && data['results'] is List) {
          allReports = (data['results'] as List)
              .map((json) => LostFoundReport.fromJson(json))
              .toList();
        }
        
        // Filter based on current tab
        switch (_currentTab) {
          case 0: // My Reports - show all statuses
            return allReports.where((r) => r.reporterId == _currentUserId).toList();
          case 1: // All Reports (excluding own reports) - only active
            return allReports.where((r) => r.reporterId != _currentUserId).toList();
          case 2: // Lost Only (excluding own reports) - only active
            return allReports.where((r) => r.isLost && r.reporterId != _currentUserId).toList();
          case 3: // Found Only (excluding own reports) - only active
            return allReports.where((r) => r.isFound && r.reporterId != _currentUserId).toList();
          default:
            return allReports;
        }
      }
      
      throw Exception('Failed to load reports: ${response.statusCode}');
    } catch (e) {
      print('Error fetching reports: $e');
      rethrow;
    }
  }

  Future<void> _deleteReport(LostFoundReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete this ${report.reportTypeDisplay.toLowerCase()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dio = Dio();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        await dio.delete(
          '${ApiConstants.baseUrl}${ApiConstants.lostFound}${report.id}/',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        setState(() {
          _reportsFuture = _fetchReportsWithDebug();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting report: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateStatus(LostFoundReport report, String newStatus) async {
    try {
      final dio = Dio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      print('Updating report ${report.id} to status: $newStatus');
      print('URL: ${ApiConstants.baseUrl}${ApiConstants.lostFound}${report.id}/');
      
      final response = await dio.patch(
        '${ApiConstants.baseUrl}${ApiConstants.lostFound}${report.id}/',
        data: {'status': newStatus},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _reportsFuture = _fetchReportsWithDebug();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $newStatus')),
          );
        }
      } else {
        throw Exception('Failed to update: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showReportOptions(LostFoundReport report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (report.isActive)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Mark as Resolved'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(report, 'resolved');
                  },
                ),
              if (report.isActive || report.isResolved)
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.orange),
                  title: const Text('Close Report'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(report, 'closed');
                  },
                ),
              if (report.isClosed || report.isResolved)
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.blue),
                  title: const Text('Reactivate Report'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(report, 'active');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Report'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditLostFoundScreen(report: report),
                    ),
                  );
                  if (result == true) {
                    await Future.delayed(const Duration(milliseconds: 300));
                    refreshReports();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Report', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteReport(report);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reportDate = DateTime(date.year, date.month, date.day);
    
    final difference = today.difference(reportDate).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'resolved':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showTabs ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showTabs ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.center,
                          labelColor: Colors.white,
                          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                          indicator: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                          tabs: const [
                            Tab(text: 'My Reports'),
                            Tab(text: 'All'),
                            Tab(text: 'Lost'),
                            Tab(text: 'Found'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _searchExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {
                          setState(() {
                            _searchExpanded = true;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                    secondChild: SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search reports...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.arrow_back, size: 20),
                                tooltip: 'Close search',
                                onPressed: () {
                                  setState(() {
                                    _searchExpanded = false;
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<LostFoundReport>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final allReports = snapshot.data ?? [];
              
              // Filter reports based on search query
              final reports = _searchQuery.isEmpty
                  ? allReports
                  : allReports.where((report) {
                      return (report.petName?.toLowerCase().contains(_searchQuery) ?? false) ||
                             report.petType.toLowerCase().contains(_searchQuery) ||
                             report.location.toLowerCase().contains(_searchQuery) ||
                             report.description.toLowerCase().contains(_searchQuery);
                    }).toList();
              
              if (reports.isEmpty) {
                if (_searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No reports found matching "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                } else {
                  String emptyMessage = 'No reports found.';
                  if (_currentTab == 0) {
                    emptyMessage = 'You haven\'t created any reports yet.';
                  } else if (_currentTab == 2) {
                    emptyMessage = 'No lost pet reports at the moment.';
                  } else if (_currentTab == 3) {
                    emptyMessage = 'No found pet reports at the moment.';
                  }
                  return Center(child: Text(emptyMessage));
                }
              }
              
              return RefreshIndicator(
                onRefresh: _refreshReports,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final isMyReport = _currentUserId != null && report.reporterId == _currentUserId;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LostFoundDetailScreen(report: report),
                            ),
                          ).then((_) => refreshReports());
                        },
                        onLongPress: isMyReport ? () => _showReportOptions(report) : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo
                            if (report.photo != null && report.photo!.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  report.photo!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      report.isLost ? Icons.pets : Icons.favorite,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Report Type & Status Badges
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: report.isLost 
                                              ? Colors.red.withOpacity(0.1) 
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          report.reportTypeDisplay,
                                          style: TextStyle(
                                            color: report.isLost ? Colors.red : Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(report.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          report.statusDisplay,
                                          style: TextStyle(
                                            color: _getStatusColor(report.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Pet Name or Type
                                  Text(
                                    report.petName ?? report.petType,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Pet Details
                                  if (report.breed != null && report.breed!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.pets, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${report.petType} - ${report.breed}',
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.pets, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            report.petType,
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Color
                                  Row(
                                    children: [
                                      const Icon(Icons.palette, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        report.color,
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Location
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          report.location,
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Date
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(report.dateLostFound),
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Description
                                  Text(
                                    report.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                  // Contact Button
                                  if (!isMyReport)
                                    InkWell(
                                      onTap: () async {
                                        final Uri launchUri = Uri(
                                          scheme: 'tel',
                                          path: report.contactPhone,
                                        );
                                        if (await canLaunchUrl(launchUri)) {
                                          await launchUrl(launchUri);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone, color: Colors.green),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Call Reporter',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  Text(
                                                    report.contactPhone,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.more_horiz, size: 18),
                                            label: const Text('Manage'),
                                            onPressed: () => _showReportOptions(report),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
