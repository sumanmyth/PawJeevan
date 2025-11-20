class LostFoundReport {
  final int id;
  final String reportType; // 'lost' or 'found'
  final String? petName;
  final String petType;
  final String? breed;
  final String color;
  final String description;
  final String location;
  final String address;
  final DateTime dateLostFound;
  final int reporterId;
  final String reporterUsername;
  final String contactPhone;
  final String? photo;
  final String status; // 'active', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;

  LostFoundReport({
    required this.id,
    required this.reportType,
    this.petName,
    required this.petType,
    this.breed,
    required this.color,
    required this.description,
    required this.location,
    required this.address,
    required this.dateLostFound,
    required this.reporterId,
    required this.reporterUsername,
    required this.contactPhone,
    this.photo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LostFoundReport.fromJson(Map<String, dynamic> json) {
    return LostFoundReport(
      id: json['id'] as int,
      reportType: json['report_type'] as String,
      petName: json['pet_name'] as String?,
      petType: json['pet_type'] as String,
      breed: json['breed'] as String?,
      color: json['color'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      address: json['address'] as String,
      dateLostFound: DateTime.parse(json['date_lost_found'] as String),
      reporterId: json['reporter'] as int,
      reporterUsername: json['reporter_username'] as String,
      contactPhone: json['contact_phone'] as String,
      photo: json['photo'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_type': reportType,
      'pet_name': petName,
      'pet_type': petType,
      'breed': breed,
      'color': color,
      'description': description,
      'location': location,
      'address': address,
      'date_lost_found': dateLostFound.toIso8601String().split('T')[0],
      'reporter': reporterId,
      'contact_phone': contactPhone,
      'photo': photo,
      'status': status,
    };
  }

  String get reportTypeDisplay {
    switch (reportType) {
      case 'lost':
        return 'Lost Pet';
      case 'found':
        return 'Found Pet';
      default:
        return reportType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';
  bool get isLost => reportType == 'lost';
  bool get isFound => reportType == 'found';
}
