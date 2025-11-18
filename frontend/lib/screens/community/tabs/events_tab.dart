import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../models/event_model.dart';
import '../events/event_detail_screen.dart';
import '../events/edit_event_screen.dart';

class EventsTab extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshCallbackRegistered;
  
  const EventsTab({super.key, this.onRefreshCallbackRegistered});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> with SingleTickerProviderStateMixin {
  late Future<List<Event>> _eventsFuture;
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
          _eventsFuture = _fetchEventsWithDebug();
        });
      }
    });
    _loadCurrentUser();
    _eventsFuture = _fetchEventsWithDebug();
    
    // Register the refresh callback with parent
    widget.onRefreshCallbackRegistered?.call(refreshEvents);
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

  // Public method to refresh events from external calls
  void refreshEvents() {
    setState(() {
      _eventsFuture = _fetchEventsWithDebug();
    });
  }

  // Manual refresh method for pull-to-refresh
  Future<void> _refreshEvents() async {
    setState(() {
      _eventsFuture = _fetchEventsWithDebug();
    });
    await _eventsFuture;
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<List<Event>> _fetchEventsWithDebug() async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    String endpoint = '${ApiConstants.baseUrl}${ApiConstants.events}';
    
    // Add filtering based on current tab
    if (_currentTab == 0) {
      // My Events (organized by me)
      endpoint = '${ApiConstants.baseUrl}${ApiConstants.events}?organizer=$_currentUserId';
    } else if (_currentTab == 1) {
      // Discover Events (all upcoming events)
      endpoint = '${ApiConstants.baseUrl}${ApiConstants.events}';
    } else if (_currentTab == 2) {
      // Joined Events (attending but not organizing)
      endpoint = '${ApiConstants.baseUrl}${ApiConstants.events}?attendee=$_currentUserId';
    }
    
    final response = await dio.get(
      endpoint,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    
    final data = response.data;
    List<Event> allEvents = [];
    
    if (data is List) {
      allEvents = data.map<Event>((e) => Event.fromJson(e)).toList();
    } else if (data is Map && data['results'] is List) {
      allEvents = (data['results'] as List).map<Event>((e) => Event.fromJson(e)).toList();
    }
    
    // Additional client-side filtering for tabs
    if (_currentTab == 0 && _currentUserId != null) {
      // My Events - only events organized by current user
      allEvents = allEvents.where((event) => event.organizerId == _currentUserId).toList();
    } else if (_currentTab == 2 && _currentUserId != null) {
      // Joined Events - attending but not organizing
      allEvents = allEvents.where((event) => 
        event.isAttending(_currentUserId!) && !event.isOrganizer(_currentUserId!)
      ).toList();
    }
    
    return allEvents;
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = Dio();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        await dio.delete(
          '${ApiConstants.baseUrl}${ApiConstants.events}${event.id}/',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        setState(() {
          _eventsFuture = _fetchEventsWithDebug();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      }
    }
  }

  Future<void> _joinEvent(Event event) async {
    if (event.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event is full'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final dio = Dio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.events}${event.id}/attend/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      setState(() {
        _eventsFuture = _fetchEventsWithDebug();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the event!')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to join event';
        
        if (e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          }
        } else if (e.response?.statusCode == 403) {
          errorMessage = 'You do not have permission to join this event';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Event not found';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to join event. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Event'),
        content: Text('Are you sure you want to leave "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dio = Dio();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        await dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.events}${event.id}/unattend/',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        setState(() {
          _eventsFuture = _fetchEventsWithDebug();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully left the event')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error leaving event: $e')),
          );
        }
      }
    }
  }

  void _showEventOptions(Event event) {
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
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Event'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditEventScreen(event: event),
                    ),
                  );
                  if (result == true) {
                    // Small delay to ensure backend has processed the update
                    await Future.delayed(const Duration(milliseconds: 300));
                    refreshEvents();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Event', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteEvent(event);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showJoinedEventOptions(Event event) {
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
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                title: const Text('Leave Event', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  _leaveEvent(event);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    
    if (eventDate == today) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                        indicator: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'My Events'),
                          Tab(text: 'Discover'),
                          Tab(text: 'Joined'),
                        ],
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
                          hintText: 'Search events...',
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
          child: FutureBuilder<List<Event>>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final allEvents = snapshot.data ?? [];
              
              // Filter events based on search query
              final events = _searchQuery.isEmpty
                  ? allEvents
                  : allEvents.where((event) {
                      return event.title.toLowerCase().contains(_searchQuery) ||
                             event.location.toLowerCase().contains(_searchQuery);
                    }).toList();
              
              if (events.isEmpty) {
                // Show different empty state messages based on current tab
                if (_searchQuery.isNotEmpty) {
                  // Search returned no results
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No events found matching "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                } else if (_currentTab == 2) {
                  // Joined tab
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'You are not attending any events yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Switch to Discover tab
                            _tabController.animateTo(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[50],
                            foregroundColor: Colors.purple,
                            elevation: 0,
                          ),
                          child: const Text('Discover Events'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: Text('No events found.'),
                  );
                }
              }
              return RefreshIndicator(
                onRefresh: _refreshEvents,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isOrganizer = _currentUserId != null && event.organizerId == _currentUserId;
                    final isAttending = _currentUserId != null && event.isAttending(_currentUserId!);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          ).then((_) => refreshEvents());
                        },
                        onLongPress: isOrganizer 
                            ? () => _showEventOptions(event) 
                            : (isAttending && !isOrganizer) 
                                ? () => _showJoinedEventOptions(event)
                                : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover Image
                            if (event.coverImage != null && event.coverImage!.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  event.coverImage!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.event, size: 64),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Event Type Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      event.eventTypeDisplay,
                                      style: const TextStyle(
                                        color: Colors.purple,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Title
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Date & Time
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatEventDate(event.startDatetime),
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
                                          event.location,
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Attendees
                                  Row(
                                    children: [
                                      const Icon(Icons.people, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        event.maxAttendees != null 
                                          ? '${event.attendeesCount}/${event.maxAttendees} attendees'
                                          : '${event.attendeesCount} attendees',
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                      if (event.isFull) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'FULL',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      if (isOrganizer) ...[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.more_horiz, size: 18),
                                            label: const Text('Manage'),
                                            onPressed: () => _showEventOptions(event),
                                          ),
                                        ),
                                      ] else if (isAttending) ...[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.check_circle, size: 18),
                                            label: const Text('Attending'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green,
                                              side: const BorderSide(color: Colors.green),
                                            ),
                                            onPressed: () => _showJoinedEventOptions(event),
                                          ),
                                        ),
                                      ] else if (_currentTab == 1) ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.event_available, size: 18),
                                            label: Text(event.isFull ? 'Event Full' : 'Join Event'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: event.isFull ? Colors.grey : Colors.purple,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: event.isFull ? null : () => _joinEvent(event),
                                          ),
                                        ),
                                      ],
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
