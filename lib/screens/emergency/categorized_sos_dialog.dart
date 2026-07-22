import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/nebah_colors.dart';
import '../../models/sos_event.dart';
import '../../services/sos_service.dart';

class CategorizedSosDialog extends StatefulWidget {
  final SosService sosService;
  final String userId;
  final String userName;
  final String userPhone;

  const CategorizedSosDialog({
    Key? key,
    required this.sosService,
    this.userId = 'usr_101',
    this.userName = 'Audu Bello',
    this.userPhone = '+234 802 999 1122',
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required SosService sosService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorizedSosDialog(sosService: sosService),
    );
  }

  @override
  State<CategorizedSosDialog> createState() => _CategorizedSosDialogState();
}

class _CategorizedSosDialogState extends State<CategorizedSosDialog> {
  EmergencyCategory _selectedCategory = EmergencyCategory.intruder;

  bool _notifyVigilante = true;
  bool _notifyPolice = true;
  bool _notifyFireService = false;
  bool _notifyAmbulance = false;
  bool _notifyEmergencyContacts = true;

  bool _isCountingDown = false;
  int _secondsRemaining = 5;
  Timer? _timer;

  bool _isDispatched = false;
  SosEvent? _dispatchedEvent;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _secondsRemaining = 5;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _executeDispatch();
      }
    });
  }

  void _cancelCountdown() {
    _timer?.cancel();
    setState(() {
      _isCountingDown = false;
      _secondsRemaining = 5;
    });
  }

  Future<void> _executeDispatch() async {
    final targets = SosTargetChannels(
      notifyVigilante: _notifyVigilante,
      notifyPolice: _notifyPolice,
      notifyFireService: _notifyFireService,
      notifyAmbulance: _notifyAmbulance,
      notifyEmergencyContacts: _notifyEmergencyContacts,
    );

    final event = await widget.sosService.triggerCategorizedSos(
      category: _selectedCategory,
      targets: targets,
      userId: widget.userId,
      userName: widget.userName,
      userPhone: widget.userPhone,
    );

    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _isDispatched = true;
        _dispatchedEvent = event;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? NebahColors.navyBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isDispatched
            ? _buildDispatchedConfirmation(isDark)
            : (_isCountingDown
                ? _buildCountdownView(isDark)
                : _buildSelectionView(isDark)),
      ),
    );
  }

  /// Step 1 & Step 2 Selection View
  Widget _buildSelectionView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag Handle & Header
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white30 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NebahColors.crimsonRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: NebahColors.crimsonRed,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interactive Emergency SOS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : NebahColors.deepNavy,
                    ),
                  ),
                  Text(
                    'Select nature of threat & target response units',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? NebahColors.slateGrey : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Emergency Category Grid
        Text(
          '1. Emergency Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : NebahColors.deepNavy,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: EmergencyCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    if (cat == EmergencyCategory.fire) {
                      _notifyFireService = true;
                    } else if (cat == EmergencyCategory.medical) {
                      _notifyAmbulance = true;
                    }
                  });
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? NebahColors.crimsonRed.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? NebahColors.crimsonRed
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        cat.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? NebahColors.crimsonRed
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Target Response Units
        Text(
          '2. Target Dispatch Channels',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : NebahColors.deepNavy,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: _notifyVigilante,
              avatar: const Icon(Icons.shield_outlined, size: 16),
              label: const Text('Community Vigilante'),
              onSelected: (val) => setState(() => _notifyVigilante = val),
            ),
            FilterChip(
              selected: _notifyPolice,
              avatar: const Icon(Icons.local_police_outlined, size: 16),
              label: const Text('Police Force'),
              onSelected: (val) => setState(() => _notifyPolice = val),
            ),
            FilterChip(
              selected: _notifyEmergencyContacts,
              avatar: const Icon(Icons.people_outline, size: 16),
              label: const Text('Family Contacts'),
              onSelected: (val) => setState(() => _notifyEmergencyContacts = val),
            ),
            FilterChip(
              selected: _notifyAmbulance,
              avatar: const Icon(Icons.medical_services_outlined, size: 16),
              label: const Text('Ambulance / ER'),
              onSelected: (val) => setState(() => _notifyAmbulance = val),
            ),
            FilterChip(
              selected: _notifyFireService,
              avatar: const Icon(Icons.local_fire_department_outlined, size: 16),
              label: const Text('Fire Service'),
              onSelected: (val) => setState(() => _notifyFireService = val),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Trigger Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _startCountdown,
            style: ElevatedButton.styleFrom(
              backgroundColor: NebahColors.crimsonRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.campaign, size: 28),
                const SizedBox(width: 10),
                Text(
                  'DISPATCH ${_selectedCategory.title.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Countdown cancel safety view
  Widget _buildCountdownView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        const Text(
          'EMERGENCY DISPATCH IN PROGRESS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: NebahColors.crimsonRed,
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: _secondsRemaining / 5.0,
                strokeWidth: 8,
                color: NebahColors.crimsonRed,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
            ),
            Text(
              '$_secondsRemaining',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : NebahColors.deepNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Sending live GPS and alert to selected security channels...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? NebahColors.slateGrey : Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _cancelCountdown,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: NebahColors.slateGrey, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'CANCEL EMERGENCY SOS',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Active Dispatch Confirmation View
  Widget _buildDispatchedConfirmation(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: NebahColors.safetyEmerald,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'SOS DISPATCHED SUCCESSFULLY!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : NebahColors.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Local Neighbourhood Vigilantes and Emergency Units in Sarkin Yama Quarter have received your live location and threat alert.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? NebahColors.slateGrey : Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_selectedCategory.emoji} ${_selectedCategory.title}'),
                ],
              ),
              if (_dispatchedEvent != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Event ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_dispatchedEvent!.id, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'ACTIVE (RESPONDING)',
                    style: TextStyle(
                      color: NebahColors.safetyEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: NebahColors.cobaltBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }
}
