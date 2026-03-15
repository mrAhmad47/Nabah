# RouteGuardian Feature Plan 🛡️

This document outlines the development roadmap for RouteGuardian, tracking completed features and outlining the plan for the Laravel/Filament v5 migration and future enhancements.

## 🚀 Phase 1: MVP (Completed Features)
**Status:** ✅ **Implemented & Working Great!**
**Goal:** Core functionality to provide safe routing and basic incident awareness.

### 1. Advanced Route Safety Features
*   ✅ **Enhanced News Coverage:** Analyzing ALL intermediate towns along routes, not just origin/destination.
*   ✅ **Intersection Detection:** Route intersection detection with dynamic switching recommendations.
*   ✅ **Reverse Geocoding:** Identifying waypoints from route geometry.
*   ✅ **N-ATLaS AI Integration:** Custom AI integration for safety scoring.
*   ✅ **Google Directions API:** Fetching multiple route alternatives (proxied to bypass CORS).
*   ✅ **Safety Scores:** 0-100 rating with color-coded warnings (Green/Yellow/Red).

### 2. User Experience & Reporting
*   ✅ **Interactive Map:** Google Maps integration with heatmap visualization.
*   ✅ **User Incident Reporting:** Local SQLite storage for offline incident reports.
*   ✅ **Platform Auto-Detection:** Auto-switching between Localhost (Web) and IP (Mobile) backends.
*   ✅ **UI/UX:** Dark Mode (Cybersecurity Theme), Incident markers.

---

## 🔄 Phase 2: Backend Migration (Laravel & Filament v5)
**Status:** 🚧 **Pending / In Progress**
**Goal:** Remove Firebase dependencies (Auth, Firestore, Storage) and replace with a dedicated Laravel backend.

### 1. Backend Transition (Laravel)
**Technology:** Laravel 11.x, FilamentPHP v5, PostgreSQL.
*   **Authentication & API:**
    *   Create REST API endpoints for the Flutter mobile app.
    *   Endpoints: `register`, `login`, `logout` (using Laravel Sanctum for token-based auth).
*   **Database (PostgreSQL via Laravel):**
    *   **Users Table:** Store profile info (managed via Laravel Eloquent).
    *   **Incidents Table:** Store user reports.
    *   **Admin Panel:** FilamentPHP v5 for web-based management of users, incidents, and system settings.
*   **Storage:**
    *   Setup Laravel Storage (local or S3) for incident photo uploads.

### 2. Frontend Work (Flutter)
**Goal:** Update Flutter app to communicate with the new Laravel REST API.
*   **Dependency Updates:**
    *   Remove: `firebase_core`, `firebase_auth`, `cloud_firestore`.
    *   Add/Update: HTTP client (e.g., `http` or `dio`) for API requests, secure storage for tokens.
*   **Service Layer Updates:**
    *   **ApiService:** Create a service to handle base URL configuration and token injection.
    *   **AuthService:** Update to call Laravel API endpoints instead of Firebase.
*   **Screen Updates:**
    *   **Auth Screens:** Update Sign In / Sign Up logic to map to new API responses.
    *   **Profile:** Fetch user data from Laravel API.
    *   **Incident Reporting:** Post new incidents to API endpoints (sync local SQLite data when online).

### 3. Migration Steps
1.  **Dependencies:** Clean up `pubspec.yaml` in Flutter app.
2.  **Config:** Initialize API Base URLs based on environment (local/production).
3.  **Refactor:** Systematically replace Firebase calls with standard HTTP requests to the Laravel backend.
4.  **Testing:** Verify Auth flow, Data persistence, and Offline capability (keeping SQLite as local cache).

---

## 🔮 Phase 3: Future Enhancements
**Status:** 📅 **Planned (Post-Migration)**
**Goal:** Optional features to add after the backend migration is stable.

### 1. Security & Monetization
*   **Security Hardening:** Rate limiting on API calls, stricter RLS policies.
*   **Ads Integration:** AdMob / Premium subscriptions.

### 2. Advanced Features
*   **Push Notifications:** Replace FCM with Laravel Reverb, Pusher, or OneSignal.
*   **Photo Uploads:** Allow attaching images to incident reports (upload to Laravel Storage).
*   **Real-time Navigation:** Turn-by-turn navigation with live GPS tracking.

---

## 📝 Next Steps
1.  **Setup:** Create Laravel project, install Filament v5, and configure the database.
2.  **Schema Design:** Create migrations and models for `User` and `Incident`.
3.  **Filament Resources:** Generate admin resources for managing data.
4.  **API Development:** Build and document REST API endpoints.
5.  **Frontend Implementation:** Update Flutter networking layer to consume new API.
6.  **Testing:** Test full flow (Register -> Login -> Report -> View).
