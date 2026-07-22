enum MissingPersonStatus {
  searching('SEARCHING', 'Active Search'),
  located('LOCATED', 'Located & Safe');

  final String code;
  final String label;
  const MissingPersonStatus(this.code, this.label);
}

class MissingPerson {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final String lastSeenLocation;
  final String lastSeenTime;
  final String description;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String photoUrl;
  final String communityQuarter;
  final MissingPersonStatus status;
  final DateTime reportedAt;

  MissingPerson({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.lastSeenLocation,
    required this.lastSeenTime,
    required this.description,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    this.photoUrl = '',
    required this.communityQuarter,
    this.status = MissingPersonStatus.searching,
    required this.reportedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'age': age,
        'gender': gender,
        'last_seen_location': lastSeenLocation,
        'last_seen_time': lastSeenTime,
        'description': description,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'photo_url': photoUrl,
        'community_quarter': communityQuarter,
        'status': status.code,
        'reported_at': reportedAt.toIso8601String(),
      };
}
