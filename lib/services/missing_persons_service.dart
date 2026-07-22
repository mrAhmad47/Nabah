import 'package:flutter/foundation.dart';
import '../models/missing_person.dart';

class MissingPersonsService {
  final List<MissingPerson> _mockRecords = [
    MissingPerson(
      id: 'mp_01',
      fullName: 'Aisha Mohammed',
      age: 14,
      gender: 'Female',
      lastSeenLocation: 'Gwallameji Primary School Gate',
      lastSeenTime: 'Yesterday, 4:30 PM',
      description: 'Wearing blue school uniform with white headscarf. Carrying a green backpack.',
      emergencyContactName: 'Mallam Mohammed',
      emergencyContactPhone: '+234 803 555 1234',
      photoUrl: '',
      communityQuarter: 'Sarkin Yama Quarter',
      status: MissingPersonStatus.searching,
      reportedAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    MissingPerson(
      id: 'mp_02',
      fullName: 'Bello Garba',
      age: 72,
      gender: 'Male',
      lastSeenLocation: 'Federal Low-Cost Central Mosque',
      lastSeenTime: '2 days ago',
      description: 'Elderly man with white beard. Wears a brown kaftan and eyeglasses. Suffers mild memory disorientation.',
      emergencyContactName: 'Usman Garba',
      emergencyContactPhone: '+234 802 888 4455',
      photoUrl: '',
      communityQuarter: 'Federal Low-Cost Quarter',
      status: MissingPersonStatus.searching,
      reportedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// Fetch all missing person reports
  Future<List<MissingPerson>> getMissingPersons() async {
    return List.from(_mockRecords);
  }

  /// Submit new missing person report
  Future<MissingPerson> reportMissingPerson(MissingPerson person) async {
    _mockRecords.insert(0, person);
    debugPrint('📢 Missing person report filed: ${person.fullName}');
    return person;
  }

  /// Update person status (e.g. mark as located)
  Future<void> markAsLocated(String id) async {
    final index = _mockRecords.indexWhere((p) => p.id == id);
    if (index != -1) {
      final old = _mockRecords[index];
      _mockRecords[index] = MissingPerson(
        id: old.id,
        fullName: old.fullName,
        age: old.age,
        gender: old.gender,
        lastSeenLocation: old.lastSeenLocation,
        lastSeenTime: old.lastSeenTime,
        description: old.description,
        emergencyContactName: old.emergencyContactName,
        emergencyContactPhone: old.emergencyContactPhone,
        photoUrl: old.photoUrl,
        communityQuarter: old.communityQuarter,
        status: MissingPersonStatus.located,
        reportedAt: old.reportedAt,
      );
    }
  }
}
