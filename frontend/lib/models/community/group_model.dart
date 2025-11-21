class Group {
  final int? id;
  final String name;
  final String slug;
  final String description;
  final String groupType;
  final String? groupTypeDisplay;
  final String? coverImage;
  final bool isPrivate;
  final int? creatorId;
  final bool? isMember;
  final String? joinKey;
  final int? membersCount;

  Group({
    this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.groupType,
    this.groupTypeDisplay,
    this.coverImage,
    required this.isPrivate,
    this.creatorId,
    this.isMember,
    this.joinKey,
    this.membersCount,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      groupType: json['group_type'],
      groupTypeDisplay: json['group_type_display'],
      coverImage: json['cover_image'],
      isPrivate: json['is_private'],
      creatorId: json['creator'],
      isMember: json['is_member'],
      joinKey: json['join_key'],
      membersCount: json['members_count'],
    );
  }
}
