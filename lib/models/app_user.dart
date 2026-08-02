enum UserRole {
  citizen,
  vigilante,
  maiAnguwa,
  districtHead,
  lgaOfficer,
  admin,
}

class EmergencyContact {
  final String name;
  final String phone;
  final bool receiveSMS;
  final bool receiveWhatsApp;

  EmergencyContact({
    required this.name,
    required this.phone,
    this.receiveSMS = true,
    this.receiveWhatsApp = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'receiveSMS': receiveSMS,
        'receiveWhatsApp': receiveWhatsApp,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        receiveSMS: json['receiveSMS'] ?? true,
        receiveWhatsApp: json['receiveWhatsApp'] ?? true,
      );
}

class AppUser {
  final String id;
  final String? phone;
  final String? email;
  final String? fullName;
  final UserRole role;
  final String? communityId;
  final String? lga;
  final String? state;
  final bool ninVerified;
  final List<EmergencyContact> emergencyContacts;
  final bool isSubscribed;
  final String subscriptionPlan;
  final DateTime createdAt;

  AppUser({
    required this.id,
    this.phone,
    this.email,
    this.fullName,
    this.role = UserRole.citizen,
    this.communityId,
    this.lga,
    this.state,
    this.ninVerified = false,
    this.emergencyContacts = const [],
    this.isSubscribed = false,
    this.subscriptionPlan = 'free',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phone,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'community_id': communityId,
      'lga': lga,
      'state': state,
      'nin_verified': ninVerified,
      'emergency_contacts': emergencyContacts.map((c) => c.toJson()).toList(),
      'is_subscribed': isSubscribed,
      'subscription_plan': subscriptionPlan,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.citizen;
    if (json['role'] != null) {
      parsedRole = UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.citizen,
      );
    }

    var contactsJson = json['emergency_contacts'];
    List<EmergencyContact> contacts = [];
    if (contactsJson is List) {
      contacts = contactsJson
          .map((c) => EmergencyContact.fromJson(Map<String, dynamic>.from(c)))
          .toList();
    }

    return AppUser(
      id: json['id'] ?? '',
      phone: json['phone_number'] ?? json['phone'],
      email: json['email'],
      fullName: json['full_name'] ?? json['displayName'],
      role: parsedRole,
      communityId: json['community_id'],
      lga: json['lga'],
      state: json['state'],
      ninVerified: json['nin_verified'] ?? false,
      emergencyContacts: contacts,
      isSubscribed: json['is_subscribed'] ?? false,
      subscriptionPlan: json['subscription_plan'] ?? 'free',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
