# Monorepo Migration Plan 📂

As RouteGuardian evolves, the decision has been made to transition the repository architecture into a **Monorepo**. This approach consolidate our multiple services into a single unifying repository, making managing the full lifecycle (Frontend, API, and AI models) much easier to test and develop in tandem.

## 🎯 The Goal

Transform the current repository, which mainly contains the Flutter application and a standalone Python `natlas_server.py` script at the root, into organized, specialized directories.

### Proposed Directory Structure

```text
route-guardian/
│
├── apps/               # Scalable applications
│   ├── api/            # 🚀 New Laravel & Filament v5 Backend Server
│   └── mobile/         # 📱 The existing Flutter Application
│
├── services/           # Microservices and specialized systems
│   └── ai/             # 🧠 Python N-ATLaS AI Server & Models
│
├── docs/               # 📖 Project Documentation
├── README.md           # 🏠 Main Project README
└── .gitignore          # 🛡️ Global Monorepo Git Ignore
```

## 📋 Execution Steps

### Step 1: Restructuring
- Create `apps/mobile/`, `apps/api/`, and `services/ai/` within the root folder.
- Move the existing Flutter `lib`, `android`, `ios`, `pubspec.yaml`, `test`, and platform folders inside `apps/mobile/`.
- Move the `natlas_server.py` (and any related dependencies/model configuration) into `services/ai/`.
- Keep `docs/`, `LICENSE`, and `README.md` at the root folder level.

### Step 2: Laravel Backend Setup
- Run `composer create-project laravel/laravel apps/api` to initialize the PHP environment directly in the monorepo structure.
- Check the `laravel_setup_checklist.md` document for the detailed FilamentPHP v5 setup, migrations, and model generation tasks.

### Step 3: Global Configuration
- Initialize a global `.gitignore` at the Monorepo root to block vendor folders (`node_modules`, `vendor/`), built outputs (`apps/mobile/build`), and sensitive environment files (`.env`).
- Ensure the Flutter path configurations and routing setups reflect the new `apps/mobile/` path (e.g. updating CI/CD scripts or IDE setup files if any).

### Step 4: Verification
- Verify running `flutter run` manually inside the `apps/mobile/` directory.
- Verify running `php artisan serve` within `apps/api/`.
- Verify the python server using `python natlas_server.py` within `services/ai/`.
