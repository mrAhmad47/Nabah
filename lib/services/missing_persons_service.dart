import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/missing_person.dart';

class MissingPersonsService {
  SupabaseClient get _supabase => Supabase.instance.client;

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

  /// Fetch all missing person reports from Supabase Cloud DB
  Future<List<MissingPerson>> getMissingPersons() async {
    try {
      final res = await _supabase
          .from('missing_persons')
          .select()
          .order('created_at', ascending: false);

      if (res.isNotEmpty) {
        final cloudItems = res.map((item) {
          return MissingPerson(
            id: item['id'] ?? '',
            fullName: item['full_name'] ?? 'Unknown Person',
            age: item['age'] ?? 18,
            gender: item['gender'] ?? 'Unspecified',
            lastSeenLocation: item['last_seen_location_name'] ?? 'Bauchi',
            lastSeenTime: 'Recently',
            description: item['description'] ?? '',
            emergencyContactName: item['contact_name'] ?? 'Family Contact',
            emergencyContactPhone: item['contact_phone'] ?? '+234 800 000 0000',
            photoUrl: item['photo_url'] ?? '',
            communityQuarter: 'Bauchi Quarter',
            status: item['case_status'] == 'found'
                ? MissingPersonStatus.located
                : MissingPersonStatus.searching,
            reportedAt: DateTime.parse(item['created_at']),
          );
        }).toList();

        return [...cloudItems, ..._mockRecords];
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching missing persons from Supabase: $e');
    }

    return List.from(_mockRecords);
  }

  /// Submit new missing person report to Supabase
  Future<MissingPerson> reportMissingPerson(MissingPerson person) async {
    _mockRecords.insert(0, person);

    try {
      await _supabase.from('missing_persons').insert({
        'full_name': person.fullName,
        'age': person.age,
        'gender': person.gender,
        'last_seen_location_name': person.lastSeenLocation,
        'description': person.description,
        'contact_name': person.emergencyContactName,
        'contact_phone': person.emergencyContactPhone,
        'photo_url': person.photoUrl,
        'case_status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('⚡ Missing person report inserted into Supabase cloud DB!');
    } catch (e) {
      debugPrint('⚠️ Supabase insert missing person error: $e');
    }

    return person;
  }

  /// Update person status (e.g. mark as located)
  Future<void> markAsLocated(String id) async {
    try {
      await _supabase.from('missing_persons').update({
        'case_status': 'found',
      }).eq('id', id);
    } catch (e) {
      debugPrint('⚠️ Error updating missing person status in Supabase: $e');
    }

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
