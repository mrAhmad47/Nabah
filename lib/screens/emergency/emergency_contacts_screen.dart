import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/nebah_colors.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final _authService = AuthService();
  List<EmergencyContact> _familyContacts = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final userProfile = await _authService.fetchUserProfile();
    if (userProfile != null) {
      setState(() {
        _familyContacts = List.from(userProfile.emergencyContacts);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContacts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final jsonContacts = _familyContacts.map((c) => c.toJson()).toList();
      await Supabase.instance.client
          .from('profiles')
          .update({'emergency_contacts': jsonContacts})
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Emergency contacts updated in Supabase cloud!')),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error saving contacts: $e');
    }
  }

  void _addContactModal() {
    if (_familyContacts.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 family/friends contacts allowed.')),
      );
      return;
    }

    _nameController.clear();
    _phoneController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: NebahColors.slate800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Emergency Contact',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contact Name',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. Alhaji Danladi',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: NebahColors.slate900,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Phone Number (+234...)',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. +234 803 123 4567',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: NebahColors.slate900,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                  setState(() {
                    _familyContacts.add(EmergencyContact(
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                    ));
                  });
                  _saveContacts();
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: NebahColors.cobaltBlue),
              child: const Text('Save Contact'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebahColors.slate900,
      appBar: AppBar(
        title: const Text('Emergency Response Contacts'),
        backgroundColor: NebahColors.slate800,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContactModal,
        backgroundColor: NebahColors.cobaltBlue,
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('FAMILY & FRIENDS (UP TO 5)', Icons.people),
                if (_familyContacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('No family contacts added yet.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._familyContacts.map((c) => Card(
                        color: NebahColors.slate800,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: NebahColors.cobaltBlue,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(c.phone, style: const TextStyle(color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _familyContacts.remove(c));
                              _saveContacts();
                            },
                          ),
                        ),
                      )),
                const SizedBox(height: 24),
                _buildSectionHeader('MY VIGILANTE GROUP', Icons.security),
                const Card(
                  color: NebahColors.slate800,
                  child: ListTile(
                    leading: Icon(Icons.shield, color: Colors.greenAccent),
                    title: Text('Bauchi Mai Anguwa Patrol Unit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Auto-connected via Community PostGIS Geofence', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('GOVERNMENT & EMERGENCY CONTROL', Icons.local_police),
                _buildGovTile('Nigeria Emergency Toll-Free', '112', Icons.phone_in_talk),
                _buildGovTile('Bauchi Police Control Room', '07055000922', Icons.local_police),
                _buildGovTile('Federal Road Safety Corps (FRSC)', '122', Icons.car_crash),
                _buildGovTile('National Emergency Management (NEMA)', '080022556362', Icons.medical_services),
                const SizedBox(height: 24),
                _buildSectionHeader('MY COMMUNITY LEADERS', Icons.account_tree),
                _buildGovTile('Mai Anguwa (Quarter Head)', '+2348030001122', Icons.person_pin),
                _buildGovTile('Sarkin District (District Head)', '+2348030003344', Icons.location_city),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: NebahColors.cobaltBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: NebahColors.cobaltBlue, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGovTile(String name, String phone, IconData icon) {
    return Card(
      color: NebahColors.slate800,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: const Icon(Icons.call, color: Colors.greenAccent),
      ),
    );
  }
}
