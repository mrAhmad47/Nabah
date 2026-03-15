# Laravel & Filament v5 Setup Checklist 🚀

Use this checklist to track the backend transition from Firebase to a dedicated Laravel application with FilamentPHP v5 for the web admin panel.

## 1. 🛠️ Laravel Project Setup
- [ ] **Create Project:** `composer create-project laravel/laravel route-guardian-backend`
- [ ] **Database Setup:** 
    - [ ] Create a PostgreSQL database.
    - [ ] Update `.env` with database credentials (`DB_CONNECTION=pgsql`, `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`).
    - [ ] Run default migrations: `php artisan migrate`.
- [ ] **Authentication (Sanctum):**
    - [ ] Install Laravel Sanctum: `php artisan install:api`.
    - [ ] Ensure the `User` model uses the `HasApiTokens` trait.

## 2. 🗄️ Database Schema (Migrations)
Create migrations for the required tables to replace Firestore.

### A. Users Table (Updates)
Extend the default `users` table to include necessary profile fields.
- [ ] Add `phone`, `avatar_url`, etc., to the `users` migration.
- [ ] Run migration: `php artisan migrate`.

### B. Incidents Table
Stores user-reported safety incidents.
- [ ] Create Migration & Model: `php artisan make:model Incident -m`.
- [ ] Add fields to migration: `user_id` (foreign key, nullable), `type`, `description`, `latitude`, `longitude`.
- [ ] Run migration: `php artisan migrate`.

## 3. 🛡️ FilamentPHP v5 Admin Panel
Set up the admin panel for managing the application data.
- [ ] **Install Filament:**
    - [ ] `composer require filament/filament:"^5.2"` it's `composer require filament/filament`).
    - [ ] `php artisan filament:install --panels`.
- [ ] **Create Admin User:** `php artisan make:filament-user`.
- [ ] **Generate Resources:**
    - [ ] Users Resource: `php artisan make:filament-resource User`.
    - [ ] Incidents Resource: `php artisan make:filament-resource Incident`.

## 4. 🔌 API Development (For Flutter App)
Create REST endpoints in `routes/api.php`.
- [ ] **Auth Endpoints:** `/api/register`, `/api/login`, `/api/logout`, `/api/user`.
- [ ] **Incident Endpoints:**
    - [ ] `GET /api/incidents` (Fetch incidents for the map).
    - [ ] `POST /api/incidents` (Submit a new report).
- [ ] **Controllers:** Create `AuthController` and `IncidentController` to handle the logic.

## 5. 📱 Flutter Integration
- [ ] **Clean Dependencies:**
    - Remove: `firebase_core`, `firebase_auth`, `cloud_firestore`.
    - Add/Update: HTTP client (`http` or `dio`), secure storage plugin (`flutter_secure_storage`).
- [ ] **Environment Setup:** Configure API Base URLs in Flutter.
- [ ] **Auth Implementation:** Update `AuthService` to call Laravel Sanctum API endpoints. Storage token securely.
- [ ] **Data Fetching:** Update services to fetch map data and incidents from the new Laravel endpoints.

## 6. ✅ Verification
- [ ] **API Tests:** Test endpoints using Postman/Insomnia.
- [ ] **Filament Tests:** Log in to the admin panel and manage Users/Incidents.
- [ ] **Flutter Tests:** Verify Auth flow, data rendering, and incident submission from the mobile app.
