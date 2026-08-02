import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../components/neon_button.dart';
import '../components/neon_card.dart';
import 'route_selection_screen.dart';
import 'alerts_screen.dart';
import 'report_incident_screen.dart';
import 'ai_analysis_screen.dart';
import 'profile_screen.dart';
import '../services/geolocation_service.dart';
import '../services/directions_service.dart';
import '../services/route_safety_news_service.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({Key? key}) : super(key: key);

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final GeolocationService _geoService = GeolocationService();
  String _currentLocationText = 'Getting location...';
  latlong2.LatLng? _currentLocation;

  // Live news state
  bool _isLoadingNews = true;
  List<SafetyWarning> _liveAlerts = [];
  int _areaSafetyScore = 80;
  String _lastUpdated = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _geoService.getCurrentLocation();
    String address;

    if (location != null) {
      address = await _geoService.getAddressFromCoordinates(location);
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _currentLocationText = address;
        });
      }
    } else {
      address = 'Lagos, Nigeria';
      if (mounted) {
        setState(() {
          _currentLocation = GeolocationService.defaultLocation;
          _currentLocationText = 'Lagos, Nigeria (Default)';
        });
      }
    }

    // Once we have an address, fetch live safety news for the area
    await _fetchAreaSafetyNews(address);
  }

  Future<void> _fetchAreaSafetyNews(String locationAddress) async {
    if (!mounted) return;
    setState(() => _isLoadingNews = true);

    try {
      // Create a dummy RouteResult representing just the current location
      final fakeRoute = RouteResult(
        routeIndex: 0,
        routeName: 'Area Safety Check',
        originAddress: locationAddress,
        destinationAddress: locationAddress,
        distanceMeters: 0,
        distanceText: '0 km',
        durationSeconds: 0,
        durationText: '0 min',
        routePoints: _currentLocation != null ? [_currentLocation!] : [],
        steps: [],
      );

      final analysis = await RouteSafetyNewsService.instance
          .analyzeRouteSafety(route: fakeRoute);

      if (!mounted) return;
      setState(() {
        _liveAlerts = analysis.warnings;
        _areaSafetyScore = analysis.safetyScore;
        _isLoadingNews = false;
        _lastUpdated = 'Just now';
      });
    } catch (e) {
      debugPrint('⚠️ Home news fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingNews = false;
        _lastUpdated = 'Unavailable';
      });
    }
  }

  /// Dynamic risk label and color based on safety score
  String get _riskLabel {
    if (_areaSafetyScore >= 80) return 'LOW RISK';
    if (_areaSafetyScore >= 60) return 'MODERATE RISK';
    if (_areaSafetyScore >= 40) return 'HIGH RISK';
    return 'DANGER ZONE';
  }

  Color get _riskColor {
    if (_areaSafetyScore >= 80) return AppTheme.neonGreen;
    if (_areaSafetyScore >= 60) return const Color(0xFFFFB800);
    return AppTheme.dangerRed;
  }

  String get _riskSummary {
    if (_liveAlerts.isEmpty) {
      return 'No major incidents detected nearby. Stay vigilant.';
    }
    final types = _liveAlerts.map((a) => a.type.displayName).toSet().join(', ');
    return '${_liveAlerts.length} alert${_liveAlerts.length > 1 ? 's' : ''} detected nearby: $types.';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Static Map Background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              image: DecorationImage(
                image: const NetworkImage(
                  "https://lh3.googleusercontent.com/aida-public/AB6AXuCg7C76ohZ4o2us3crTSCsf33WFBrqCcpMcLwd0AAEiXLRBb5vQiqRNMe_NMdjNIxIajtLJf5QoRuZFAb7HIChnZ3n8m5tSYO1QHttkdfxxAqsedkc0kS4cBKFciM6DeCgdPB7vwq5f5MhIT9C2a3NojvAz8JkVlgUpMNd83mgXe0_sMbLskiTLFJoPH7z_e9VHdl3otPimXs3ucx2HAD504Sf2i_TVOa4Rol9WpVRAoiDPMkr92fI5jDcQxySMRl2jPzIOjlAAFwTg",
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.6),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
        ),

        // Custom App Bar (Floating)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nebah',
                    style: AppTheme.titleStyle.copyWith(fontSize: 22, letterSpacing: 1.5),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main Content Overlay
        Positioned.fill(
          top: 100,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on, color: AppTheme.neonGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Current Location: $_currentLocationText',
                          style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppTheme.neonGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Dynamic Area Safety Card
                NeonCard(
                  hasGlow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isLoadingNews ? 'SCANNING AREA...' : _riskLabel,
                              style: AppTheme.titleStyle.copyWith(
                                color: _isLoadingNews ? Colors.grey : _riskColor,
                                fontSize: 20,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          if (!_isLoadingNews) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _riskColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _riskColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '$_areaSafetyScore%',
                                style: TextStyle(
                                  color: _riskColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.neonGreen,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Safety score bar
                      if (!_isLoadingNews) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _areaSafetyScore / 100,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        _isLoadingNews
                            ? 'Fetching live safety data for your area...'
                            : _riskSummary,
                        style: AppTheme.bodyStyle.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingNews ? '' : 'Updated: $_lastUpdated',
                        style: AppTheme.bodyStyle.copyWith(
                          color: _riskColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AlertsScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.accentBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(color: AppTheme.accentBlue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Start Navigation
                NeonButton(
                  text: 'Start SafeRoute Navigation',
                  isPrimary: true,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RouteSelectionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Meta Text
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Check Another Location',
                      style: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.neonGreen.withValues(alpha: 0.7),
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Shortcut Menu
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AlertsScreen()),
                          );
                        },
                        child: _buildShortcutItem(Icons.notifications_active, 'Alerts'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIAnalysisScreen()),
                          );
                        },
                        child: _buildShortcutItem(Icons.auto_awesome, 'Gemini AI'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportIncidentScreen()),
                          );
                        },
                        child: _buildShortcutItem(Icons.report, 'Report'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildShortcutItem(Icons.verified_user, 'Safe')),
                  ],
                ),
                const SizedBox(height: 16),

                // Safety Statistics Strip
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          _liveAlerts.isEmpty ? '0' : '${_liveAlerts.length}',
                          'Alerts Nearby',
                          Colors.white,
                        ),
                        const VerticalDivider(color: Colors.white24, width: 1),
                        _buildStatItem('$_areaSafetyScore%', 'Safety Score', _riskColor),
                        const VerticalDivider(color: Colors.white24, width: 1),
                        _buildStatItem(
                          _isLoadingNews ? '...' : 'Live',
                          'AI Status',
                          AppTheme.neonGreen,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Live Alerts Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Safety Alerts',
                            style: AppTheme.titleStyle.copyWith(fontSize: 18),
                          ),
                          if (_isLoadingNews)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.neonGreen,
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => _fetchAreaSafetyNews(_currentLocationText),
                              child: const Icon(Icons.refresh, color: AppTheme.neonGreen, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Show live alerts or fallback message
                      if (_isLoadingNews)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: AppTheme.neonGreen),
                              SizedBox(height: 12),
                              Text(
                                'Fetching live news from area...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else if (_liveAlerts.isEmpty)
                        _buildAlertCard(
                          icon: Icons.verified_user,
                          iconColor: AppTheme.neonGreen,
                          bgHex: 0xFF39FF14,
                          title: 'Area Clear',
                          subtitle: 'No security incidents detected near you',
                          time: _lastUpdated,
                        )
                      else
                        ..._liveAlerts.take(4).map((alert) => _buildLiveAlertCard(alert)),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AlertsScreen()),
                          );
                        },
                        child: const Text(
                          'See All Alerts →',
                          style: TextStyle(color: AppTheme.neonGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // SOS Button
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: AppTheme.dangerRed,
            child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  /// Alert card for LIVE news items from N-ATLaS
  Widget _buildLiveAlertCard(SafetyWarning alert) {
    final iconData = _warningIcon(alert.type);
    final color = _warningColor(alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.type.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${alert.location} — ${alert.description}',
                  style: TextStyle(
                    color: AppTheme.neonGreen.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                alert.recencyLabel.isNotEmpty ? alert.recencyLabel : 'Live',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${alert.severityImpact}%',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _warningIcon(WarningType type) {
    switch (type) {
      case WarningType.crime: return Icons.gpp_maybe;
      case WarningType.kidnapping: return Icons.warning_amber;
      case WarningType.badRoad: return Icons.construction;
      case WarningType.weather: return Icons.thunderstorm;
      case WarningType.traffic: return Icons.traffic;
      case WarningType.accident: return Icons.car_crash;
    }
  }

  Color _warningColor(WarningType type) {
    switch (type) {
      case WarningType.crime: return Colors.amber;
      case WarningType.kidnapping: return AppTheme.dangerRed;
      case WarningType.badRoad: return Colors.orange;
      case WarningType.weather: return AppTheme.accentBlue;
      case WarningType.traffic: return AppTheme.accentBlue;
      case WarningType.accident: return Colors.deepOrange;
    }
  }

  Widget _buildShortcutItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.neonGreen),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color valueColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.neonGreen.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color iconColor,
    required int bgHex,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(bgHex).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.neonGreen.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
