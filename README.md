# School Bus Tracker 🚌

A real-time school bus tracking system built with Flutter and Firebase. This app features three distinct user roles (Admin, Driver, and Parent) to ensure a safe and efficient commute for students.

## 🚀 Features
- **Role-Based Authentication:** Secure login for Admins, Drivers, and Parents.
- **Admin Dashboard:** Create and manage users; assign Drivers and Parents to specific Bus IDs.
- **Driver Mode:** Real-time GPS simulation that pushes location data to Firebase.
- **Parent Mode:** Live Google Maps integration to track the assigned bus's movement in real-time.
- **Live Sync:** Powered by Firebase Realtime Database for low-latency updates.

## 🛠️ Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase Authentication & Cloud Firestore
- **Live Database:** Firebase Realtime Database
- **Maps:** Google Maps Flutter Plugin

## 📦 Installation
1. Clone the repository: `git clone https://github.com/zaba-baramy/school-bus-tracker.git`
2. Run `flutter pub get` to install dependencies.
3. Add your `google-services.json` (Android) to `android/app/`.
4. Ensure your Google Maps API Key is set in `AndroidManifest.xml`.
5. Run the app: `flutter run`.
