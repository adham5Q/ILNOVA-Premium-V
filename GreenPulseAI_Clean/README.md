# GreenPulse AI

A Flutter mobile application focused on environmental sustainability.

## Screens and modules
- Authentication: login, sign up, email verification and phone OTP
- Home and profile
- Waste report and recycling
- Collection points
- AI waste scan
- Partner companies: registration, dashboard, company details and admin
- Citizen partner requests

## Tech stack
- Flutter and Dart
- Firebase
- Local database helper
- Separate service files for authentication, partners and phone OTP

## Project structure
    lib/
      main.dart
      auth_gate.dart, auth_service.dart, phone_otp_service.dart
      login_screen.dart, signup_screen.dart, otp_screen.dart, email_verification_screen.dart
      home_screen.dart, profile_screen.dart
      waste_report_screen.dart, recycling_screen.dart, collection_points_screen.dart, ai_waste_scan_screen.dart
      partner_*.dart, company_partner_dashboard.dart, citizen_partner_requests_screen.dart
      database_helper.dart

## Getting started
1. Run `flutter pub get`
2. Create your own Firebase project and generate `lib/firebase_options.dart` and `android/app/google-services.json` with `flutterfire configure`. These two files are not included in this repository for security.
3. Run `flutter run`