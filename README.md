# School Bus Tracker 🚌
A real-time school bus tracking ecosystem built with Flutter and Firebase. This project provides a secure interface for Admins, Drivers, and Parents to coordinate student transportation.

---

## 🚀 Features

* **Role-Based Access:** Dedicated dashboards and logic for **Admins**, **Drivers**, and **Parents**.
* **Admin Control:** Centralized management to register users and link Parents/Drivers to specific Bus IDs.
* **Live Tracking:** Real-time driver location updates pushed to **Cloud Firestore** and visualized on the Parent’s map.
* **Google Maps Integration:** High-precision marker movement and camera synchronization.
* **OTP Authentication:** Secure login verification using **EmailJS** for parent accounts.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase Auth & Cloud Firestore
* **Maps:** Google Maps Flutter Plugin
* **Email Service:** EmailJS

---

## 🛡️ Security Note

To prevent unauthorized API usage and billing, sensitive configuration files have been excluded from this repository via `.gitignore`:
* `google-services.json` (Android)
* `firebase_options.dart` (Flutter)
* **API Keys:** Replaced with placeholders in the source code.

---

## 📦 Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/zaba-baramy/school-bus-tracker.git](https://github.com/zaba-baramy/school-bus-tracker.git)
    ```
2.  **Configuration:** * Add your own `google-services.json` to `android/app/`.
    * Ensure your Google Maps API Key is set in `AndroidManifest.xml`.
3.  **Run the app:**
    ```bash
    flutter pub get
    flutter run
    ```