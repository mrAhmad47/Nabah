/// SOS Mode: Stealth Hardware Button Panic vs Interactive Categorized In-App SOS
enum SosMode {
  hardwarePanic('HARDWARE_PANIC', 'Hardware Panic (Stealth)'),
  interactiveCategorized('INTERACTIVE_CATEGORIZED', 'In-App Categorized SOS');

  final String code;
  final String label;
  const SosMode(this.code, this.label);
}

/// Categories for In-App Interactive SOS
enum EmergencyCategory {
  intruder(
    'INTRUDER',
    'Intruders / Robbery',
    '🥷',
    'Suspicious entry, armed robbery, or home invasion threat',
  ),
  medical(
    'MEDICAL',
    'Medical Emergency',
    '🏥',
    'Sudden illness, injury, collapse, or medical distress',
  ),
  fire(
    'FIRE',
    'Fire Outbreak',
    '🔥',
    'Building fire, gas explosion, or electrical fire outbreak',
  ),
  accident(
    'ACCIDENT',
    'Road Accident / Assault',
    '🚗',
    'Traffic collision, vehicle attack, breakdown, or physical assault',
  ),
  suspiciousActivity(
    'SUSPICIOUS',
    'Suspicious Activity',
    '👁️',
    'Unfamiliar suspicious individuals, stalking, or boundary threat',
  );

  final String code;
  final String title;
  final String emoji;
  final String description;
  const EmergencyCategory(this.code, this.title, this.emoji, this.description);
}

/// Target dispatch channels selected for Emergency SOS
class SosTargetChannels {
  final bool notifyVigilante;
  final bool notifyPolice;
  final bool notifyFireService;
  final bool notifyAmbulance;
  final bool notifyEmergencyContacts;

  const SosTargetChannels({
    this.notifyVigilante = true,
    this.notifyPolice = true,
    this.notifyFireService = false,
    this.notifyAmbulance = false,
    this.notifyEmergencyContacts = true,
  });

  Map<String, dynamic> toJson() => {
        'notify_vigilante': notifyVigilante,
        'notify_police': notifyPolice,
        'notify_fire_service': notifyFireService,
        'notify_ambulance': notifyAmbulance,
        'notify_emergency_contacts': notifyEmergencyContacts,
      };

  factory SosTargetChannels.fromJson(Map<String, dynamic> json) {
    return SosTargetChannels(
      notifyVigilante: json['notify_vigilante'] ?? true,
      notifyPolice: json['notify_police'] ?? true,
      notifyFireService: json['notify_fire_service'] ?? false,
      notifyAmbulance: json['notify_ambulance'] ?? false,
      notifyEmergencyContacts: json['notify_emergency_contacts'] ?? true,
    );
  }
}

/// Status for SOS Emergency dispatch event
enum SosStatus {
  dispatched('DISPATCHED', 'Dispatched'),
  responding('RESPONDING', 'Responding'),
  resolved('RESOLVED', 'Resolved');

  final String code;
  final String label;
  const SosStatus(this.code, this.label);

  static SosStatus fromString(String val) {
    return SosStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == val.toUpperCase(),
      orElse: () => SosStatus.dispatched,
    );
  }
}

/// Data structure representing an active or dispatched SOS Emergency event.
class SosEvent {
  final String id;
  final SosMode mode;
  final EmergencyCategory category;
  final SosTargetChannels targets;
  final double latitude;
  final double longitude;
  final String address;
  final int batteryLevel;
  final double speed;
  final String userId;
  final String userName;
  final String userPhone;
  final DateTime timestamp;
  final SosStatus status;

  SosEvent({
    required this.id,
    required this.mode,
    required this.category,
    required this.targets,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.batteryLevel = 100,
    this.speed = 0.0,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.timestamp,
    this.status = SosStatus.dispatched,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.code,
        'category': category.code,
        'targets': targets.toJson(),
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'battery_level': batteryLevel,
        'speed': speed,
        'user_id': userId,
        'user_name': userName,
        'user_phone': userPhone,
        'timestamp': timestamp.toIso8601String(),
        'status': status.code,
      };
}
