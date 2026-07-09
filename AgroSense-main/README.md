# AgroSense - Smart Farming Assistant

## Overview
AgroSense is an offline-first mobile application designed for Indian farmers, providing land management, weather intelligence, market data, and AI-powered farming assistance.

## Architecture
- **Pattern:** Clean Architecture (Data, Domain, Presentation)
- **State Management:** Riverpod
- **Database:** Drift (SQLite) for offline-first capability
- **Backend:** Supabase (Auth, PostgreSQL, Storage, Edge Functions)

## Key Features
1. **Offline-First Architecture** - All data operations work offline with background sync
2. **GIS Land Management** - Draw and manage field boundaries
3. **Weather Intelligence** - Real-time weather with AI-generated advisories
4. **Market Intelligence** - Mandi prices and trends
5. **AI Assistant** - Gemini-powered farming advisor
6. **Crop Management** - Task scheduling and crop lifecycle tracking
7. **Community Forum** - Connect with other farmers
8. **Government Schemes** - Eligibility checker

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.2.0)
- Supabase Project configured
- Android Studio / VS Code

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Configure Supabase:
   - Create a Supabase project at https://supabase.com
   - Update Supabase URL and anon key in `lib/core/constants/app_constants.dart`
4. Generate code: `flutter pub run build_runner build --delete-conflicting-outputs`
5. Run: `flutter run`

## Project Structure
```
lib/
├── core/                   # Core utilities, constants, themes
├── data/                   # Data layer (APIs, local DB, repositories)
├── domain/                 # Business logic (entities, use cases)
├── presentation/           # UI layer (screens, widgets, state)
└── main.dart              # Entry point
```

## Technologies Used
- **Flutter & Dart** - Cross-platform mobile framework
- **Riverpod 2.6.1** - State management and dependency injection
- **Drift 2.28.2** - Type-safe SQL database (offline-first SQLite)
- **Supabase** - Backend-as-a-Service
  - Supabase Auth (Phone OTP & OAuth)
  - PostgreSQL Database (Cloud sync)
  - Supabase Storage (Image storage)
  - Edge Functions (Serverless functions)
- **flutter_map 6.2.1** - Interactive maps for GIS field management
- **geolocator 10.1.1** - GPS location services
- **Google Generative AI (Gemini)** - AI-powered farming advisor
- **flutter_tts 4.2.3** - Text-to-speech for voice output
- **image_picker** - Crop photo capture
- **workmanager** - Background sync scheduling
- **dio 5.9.0** - HTTP client for API calls
- **flutter_secure_storage 9.2.4** - Secure credential storage
- **easy_localization** - Multi-language support (English, Hindi, Tamil, Telugu, Malayalam)
- **fl_chart 0.66.2** - Data visualization charts

## License
HARI PRASATH S S.
