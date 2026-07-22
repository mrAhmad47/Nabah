import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/nebah_colors.dart';
import '../../models/missing_person.dart';
import '../../services/missing_persons_service.dart';

class MissingPersonsScreen extends StatefulWidget {
  final MissingPersonsService service;

  const MissingPersonsScreen({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<MissingPersonsScreen> createState() => _MissingPersonsScreenState();
}

class _MissingPersonsScreenState extends State<MissingPersonsScreen> {
  List<MissingPerson> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = await widget.service.getMissingPersons();
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _showReportDialog() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final locationController = TextEditingController();
    final descController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            'Report Missing Person',
            style: TextStyle(color: isDark ? Colors.white : NebahColors.deepNavy),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Last Seen Location'),
                ),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Clothing / Description'),
                ),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contact Name'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final nav = Navigator.of(ctx);
                  final newPerson = MissingPerson(
                    id: 'mp_${DateTime.now().millisecondsSinceEpoch}',
                    fullName: nameController.text,
                    age: int.tryParse(ageController.text) ?? 18,
                    gender: 'Unspecified',
                    lastSeenLocation: locationController.text.isEmpty
                        ? 'Sarkin Yama Quarter'
                        : locationController.text,
                    lastSeenTime: 'Just now',
                    description: descController.text,
                    emergencyContactName: contactController.text.isEmpty
                        ? 'Family Representative'
                        : contactController.text,
                    emergencyContactPhone: phoneController.text.isEmpty
                        ? '+234 803 000 1122'
                        : phoneController.text,
                    communityQuarter: 'Sarkin Yama Quarter',
                    reportedAt: DateTime.now(),
                  );

                  await widget.service.reportMissingPerson(newPerson);
                  nav.pop(true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: NebahColors.crimsonRed),
              child: const Text('SUBMIT REPORT', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    ageController.dispose();
    locationController.dispose();
    descController.dispose();
    contactController.dispose();
    phoneController.dispose();

    if (result == true && mounted) {
      await _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Missing Persons Noticeboard'),
        backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportDialog,
        backgroundColor: NebahColors.crimsonRed,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Report Missing Person', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _reports.length,
              itemBuilder: (ctx, index) {
                final item = _reports[index];
                final isSearching = item.status == MissingPersonStatus.searching;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSearching
                          ? NebahColors.crimsonRed.withValues(alpha: 0.5)
                          : NebahColors.safetyEmerald,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSearching
                                  ? NebahColors.crimsonRed.withValues(alpha: 0.15)
                                  : NebahColors.safetyEmerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.status.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSearching
                                    ? NebahColors.crimsonRed
                                    : NebahColors.safetyEmerald,
                              ),
                            ),
                          ),
                          Text(
                            item.communityQuarter,
                            style: const TextStyle(fontSize: 12, color: NebahColors.slateGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: NebahColors.cobaltBlue.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 36, color: NebahColors.cobaltBlue),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.fullName} (${item.age} yrs)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : NebahColors.deepNavy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Last Seen: ${item.lastSeenLocation}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? NebahColors.slateGrey : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const Divider(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact: ${item.emergencyContactName}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item.emergencyContactPhone,
                                style: const TextStyle(fontSize: 11, color: NebahColors.slateGrey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone, color: NebahColors.safetyEmerald),
                                onPressed: () async {
                                  final Uri url = Uri.parse('tel:${item.emergencyContactPhone}');
                                  if (await canLaunchUrl(url)) await launchUrl(url);
                                },
                              ),
                              if (isSearching)
                                TextButton(
                                  onPressed: () async {
                                    await widget.service.markAsLocated(item.id);
                                    await _loadReports();
                                  },
                                  child: const Text('Mark Found'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
