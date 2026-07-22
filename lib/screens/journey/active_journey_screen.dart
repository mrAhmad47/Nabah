import 'package:flutter/material.dart';
import '../../core/theme/nebah_colors.dart';
import '../../models/journey_event.dart';
import '../../services/journey_service.dart';

class ActiveJourneyScreen extends StatefulWidget {
  final JourneyService journeyService;

  const ActiveJourneyScreen({
    Key? key,
    required this.journeyService,
  }) : super(key: key);

  @override
  State<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends State<ActiveJourneyScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<JourneyEvent?>(
      stream: widget.journeyService.journeyStream,
      initialData: widget.journeyService.activeJourney,
      builder: (context, snapshot) {
        final journey = snapshot.data;

        return Scaffold(
          backgroundColor: isDark ? NebahColors.navyBackground : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Live Journey Guardian'),
            backgroundColor: isDark ? NebahColors.navyBackground : Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: journey == null
              ? _buildStartJourneyView(isDark)
              : _buildActiveTrackingView(journey, isDark),
        );
      },
    );
  }

  /// View when no journey is active -> Start trip
  Widget _buildStartJourneyView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NebahColors.cobaltBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: NebahColors.cobaltBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alt_route, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Trip Protection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NebahColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nebah monitors your route, updates your ETA, and alerts contacts if you deviate or stop unexpectedly.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? NebahColors.slateGrey : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Quick Start Monitored Trip',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : NebahColors.deepNavy,
            ),
          ),
          const SizedBox(height: 12),

          _buildTripOptionTile(
            origin: 'Sarkin Yama Quarter, Gwallameji',
            dest: 'Bauchi Central Market',
            estTime: '22 mins',
            distance: '12 km',
            isDark: isDark,
            onTap: () {
              widget.journeyService.startJourney(
                originName: 'Sarkin Yama Quarter, Gwallameji',
                destinationName: 'Bauchi Central Market',
                estimatedMinutes: 22,
                distanceKm: 12,
              );
            },
          ),
          const SizedBox(height: 12),

          _buildTripOptionTile(
            origin: 'Federal Low-Cost Housing',
            dest: 'ATBU Gubi Campus Main Gate',
            estTime: '35 mins',
            distance: '24 km',
            isDark: isDark,
            onTap: () {
              widget.journeyService.startJourney(
                originName: 'Federal Low-Cost Housing',
                destinationName: 'ATBU Gubi Campus Main Gate',
                estimatedMinutes: 35,
                distanceKm: 24,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Active Journey Monitoring View
  Widget _buildActiveTrackingView(JourneyEvent journey, bool isDark) {
    final isArrived = journey.status == JourneyStatus.arrived;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // STATUS HEADER BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isArrived
                  ? NebahColors.safetyEmerald.withValues(alpha: 0.15)
                  : NebahColors.cobaltBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isArrived ? NebahColors.safetyEmerald : NebahColors.cobaltBlue,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isArrived ? Icons.check_circle : Icons.navigation_outlined,
                  size: 18,
                  color: isArrived ? NebahColors.safetyEmerald : NebahColors.cobaltBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  journey.status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isArrived ? NebahColors.safetyEmerald : NebahColors.cobaltBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PROGRESS & ETA CARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  isArrived ? 'YOU HAVE ARRIVED SAFELY!' : '${(journey.currentProgressPercent * 100).toInt()}% COMPLETED',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white : NebahColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: journey.currentProgressPercent,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                  color: isArrived ? NebahColors.safetyEmerald : NebahColors.cobaltBlue,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Origin:', style: TextStyle(fontSize: 12, color: NebahColors.slateGrey)),
                        const SizedBox(height: 2),
                        Text(
                          journey.originName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Destination:', style: TextStyle(fontSize: 12, color: NebahColors.slateGrey)),
                        const SizedBox(height: 2),
                        Text(
                          journey.destinationName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // EMERGENCY CONTACT NOTIFICATION BADGE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NebahColors.safetyEmerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NebahColors.safetyEmerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_outlined, color: NebahColors.safetyEmerald, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live trip link shared with ${journey.emergencyContactsNotified.first}. Arrival alert will trigger automatically.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ACTION BUTTONS
          if (!isArrived) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => widget.journeyService.confirmArrival(),
                icon: const Icon(Icons.check_circle_outline, size: 24),
                label: const Text(
                  'CONFIRM SAFE ARRIVAL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NebahColors.safetyEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => widget.journeyService.cancelJourney(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: NebahColors.slateGrey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'CANCEL TRIP MONITORING',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => widget.journeyService.cancelJourney(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NebahColors.cobaltBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'START NEW TRIP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripOptionTile({
    required String origin,
    required String dest,
    required String estTime,
    required String distance,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NebahColors.cobaltBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car_outlined, color: NebahColors.cobaltBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : NebahColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From: $origin • $estTime ($distance)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? NebahColors.slateGrey : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded, color: NebahColors.cobaltBlue, size: 28),
          ],
        ),
      ),
    );
  }
}
