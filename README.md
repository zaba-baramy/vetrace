School Bus Tracker 🚌
A real-time school bus tracking ecosystem built with Flutter and Firebase. This project provides a secure interface for Admins, Drivers, and Parents to coordinate student transportation.

🚀 Features
Role-Based Access: Dedicated dashboards for Admins, Drivers, and Parents.

Admin Control: Manage user registration and link Parents/Drivers to specific Bus IDs.

Live Tracking: Driver location is pushed to Cloud Firestore and visualized on the Parent’s map.

Google Maps Integration: Real-time marker movement and camera updates.

OTP Authentication: Secure login verification using EmailJS.

🛠️ Tech Stack
Frontend: Flutter (Dart)

Backend: Firebase Auth & Cloud Firestore

Maps: Google Maps Flutter Plugin

Email Service: EmailJS

🛡️ Security Note
To prevent unauthorized API usage and billing, sensitive configuration files have been excluded from this repository:

google-services.json (Android)

firebase_options.dart (Flutter)

API Keys (Masked in source code)

📦 Installation
Clone the repository:

Bash
git clone https://github.com/zaba-baramy/vetrace.git
Configuration: Add your own google-services.json to android/app/ and ensure your Google Maps API Key is set in AndroidManifest.xml.

Run:

Bash
flutter pub get
flutter run