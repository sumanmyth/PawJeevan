class Event {
  final int id;
  final String title;
  final String description;
  final String eventType;
  final String location;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final int organizerId;
  final String organizerUsername;
  final String? organizerAvatar;
  final int? groupId;
  final String? groupName;
  final List<int> attendeeIds;
  final int? maxAttendees;
  final String? coverImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    required this.location,
    required this.address,
    this.latitude,
    this.longitude,
    required this.startDatetime,
    required this.endDatetime,
    required this.organizerId,
    required this.organizerUsername,
    this.organizerAvatar,
    this.groupId,
    this.groupName,
    required this.attendeeIds,
    this.maxAttendees,
    this.coverImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Parse attendees - could be list of IDs or list of user objects
    List<int> attendeeIds = [];
    if (json['attendees'] != null) {
      final attendeesData = json['attendees'];
      if (attendeesData is List) {
        for (var item in attendeesData) {
          if (item is int) {
            attendeeIds.add(item);
          } else if (item is Map && item['id'] != null) {
            attendeeIds.add(item['id'] as int);
          }
        }
      }
    }

    return Event(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      eventType: json['event_type'] as String,
      location: json['location'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: DateTime.parse(json['end_datetime'] as String),
      organizerId: json['organizer'] is int ? json['organizer'] as int : json['organizer']['id'] as int,
      organizerUsername: json['organizer_username'] as String? ?? (json['organizer'] is Map ? json['organizer']['username'] as String : ''),
      organizerAvatar: json['organizer_avatar'] as String?,
      groupId: json['group'] as int?,
      groupName: json['group_name'] as String?,
      attendeeIds: attendeeIds,
      maxAttendees: json['max_attendees'] as int?,
      coverImage: json['cover_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'location': location,
      'address': address,
      'latitude': latitude?.toString(),
      'longitude': longitude?.toString(),
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'organizer': organizerId,
      'group': groupId,
      'attendees': attendeeIds,
      'max_attendees': maxAttendees,
      'cover_image': coverImage,
    };
  }

  int get attendeesCount => attendeeIds.length;

  bool get isFull => maxAttendees != null && attendeesCount >= maxAttendees!;

  bool isAttending(int userId) => attendeeIds.contains(userId);

  bool isOrganizer(int userId) => organizerId == userId;

  String get eventTypeDisplay {
    switch (eventType) {
      case 'meetup':
        return 'Pet Meetup';
      case 'training':
        return 'Training Session';
      case 'adoption':
        return 'Adoption Drive';
      case 'fundraiser':
        return 'Fundraiser';
      case 'competition':
        return 'Competition';
      case 'other':
        return 'Other';
      default:
        return eventType;
    }
  }
}
