/// Route names for Nebah application navigation using GoRouter
class RouteNames {
  static const String root = '/';
  
  // Onboarding
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingAuth = '/onboarding/auth';
  static const String onboardingPermissions = '/onboarding/permissions';
  static const String onboardingLocation = '/onboarding/location';
  static const String onboardingEmergencySetup = '/onboarding/emergency-setup';
  static const String onboardingTour = '/onboarding/tour';

  // Main Core Tabs
  static const String home = '/home';
  static const String safetyMap = '/map';
  static const String emergency = '/emergency';
  static const String community = '/community';
  static const String profile = '/profile';

  // Route Guardian Module
  static const String routeGuardian = '/route-guardian';
  static const String activeTrip = '/route-guardian/active';

  // Community Sub-screens
  static const String reportIncident = '/community/report';
  static const String communityHierarchy = '/community/hierarchy';
  static const String announcements = '/community/announcements';
  static const String vigilanteId = '/community/vigilante-id';

  // Emergency Sub-screens
  static const String panicConfig = '/emergency/panic-config';
  static const String interactiveSos = '/emergency/interactive-sos';
  static const String emergencyContacts = '/emergency/contacts';
  static const String emergencyCard = '/emergency/card';

  // AI Assistant & Resources
  static const String aiAssistant = '/ai-assistant';
  static const String resources = '/resources';
}
