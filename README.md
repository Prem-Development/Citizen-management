# 🇱🇰 GS Citizen Management System

A modern, offline-first Android application developed using Flutter for Grama Sevaka Officers to efficiently manage and maintain citizen information digitally.

The application is designed to simplify citizen data management, searching, editing, document generation, image management, and data backup without requiring an internet connection.

---

## 📱 Project Overview

The **GS Citizen Management System** is an offline Android application designed specifically for Grama Sevaka Officers.

Traditional citizen record management often depends on paper-based documents and manual searching. This application provides a digital solution that allows officers to securely manage citizen records using an Android device.

The application works completely offline and stores all data locally on the device using SQLite.

---

## 🎯 Objectives

The main objectives of this project are:

- Digitize citizen information management
- Reduce dependency on paper-based records
- Provide fast citizen searching
- Allow officers to manage citizen information easily
- Support citizen profile images
- Generate PDF reports
- Provide backup and restore functionality
- Work completely offline
- Provide Tamil and English language support
- Improve efficiency and reduce manual workload

---

## ✨ Key Features

### 👤 Citizen Management

- Add new citizen records
- View citizen information
- Edit existing records
- Delete citizen records
- Store detailed citizen information
- Store citizen profile images

### 🔍 Search & Filter

- Search citizens using NIC
- Search citizen records quickly
- Filter citizen information
- View filtered results
- Easy access to citizen details

### 📊 Dynamic Data Fields

The application supports additional customizable fields.

Officers can maintain extra citizen information without depending only on predefined fields.

This provides an Excel-like flexible data management experience.

### 📷 Image Management

- Capture images using the device camera
- Select images from gallery
- Store citizen images locally
- View images inside the application
- Zoom and inspect images

### 📄 PDF Export

The application supports PDF document generation.

Users can:

- Generate complete citizen reports
- Generate filtered citizen reports
- Export citizen information as PDF
- Print generated PDF documents

### 💾 Backup & Restore

The application provides local data backup functionality.

Features include:

- Create database backups
- Export backup as ZIP
- Restore citizen data
- Protect important records from accidental data loss

### 🌐 Offline First

The application does **not require an internet connection**.

All major operations are performed locally on the Android device.

This allows the application to be used in areas where internet connectivity may be limited or unavailable.

### 🌍 Language Support

The application supports:

- 🇱🇰 Tamil
- 🇬🇧 English

---

## 🛠️ Technology Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Mobile application development |
| Dart | Programming language |
| SQLite | Local database |
| Provider | State management |
| Android | Target platform |
| Material Design | User interface |

---

## 📦 Main Flutter Packages

### Database

```yaml
sqflite
path

Used for local SQLite database management.

State Management
provider

Used to manage application state.

Image Management
image_picker
image
photo_view

Used for camera, gallery, image processing, and image viewing.

PDF
pdf
printing

Used for PDF generation, preview, and printing.

Backup
archive

Used to create and extract ZIP backup files.

File Management
path_provider
file_picker
permission_handler

Used for local file access, file selection, and Android permissions.

Preferences
shared_preferences

Used to store local application preferences.

Date & Formatting
intl

Used for date and number formatting.

🏗️ Application Architecture

The application follows a structured Flutter architecture.

GS Citizen Management
│
├── Presentation Layer
│   ├── Screens
│   ├── Widgets
│   └── UI Components
│
├── State Management
│   └── Provider
│
├── Data Layer
│   ├── SQLite Database
│   ├── Models
│   └── Services
│
├── File Management
│   ├── Images
│   ├── PDF
│   └── Backup / Restore
│
└── Local Storage
    ├── SQLite
    └── Shared Preferences
🗄️ Data Storage

Citizen information is stored locally using SQLite.

The application does not depend on:

Firebase
Cloud database
Online APIs
External servers

This design provides:

Offline availability
Faster local operations
Reduced network dependency
Better control over locally stored citizen records
🔐 Privacy & Security

Citizen information is sensitive and should be handled responsibly.

The application is designed with a local-first approach.

Important Characteristics
Citizen data is stored locally
No Firebase database is used
No online citizen database is used
No cloud synchronization is required
Internet access is not required for normal application usage

Users should still protect their Android device and backup files from unauthorized access.

📱 Supported Platform
Android

The primary target platform is Android.

The application is designed to run on modern Android devices.

💻 Development Environment

Recommended development environment:

Flutter
Dart
Android Studio
Android SDK
VS Code / Android Studio
Git
GitHub
🚀 Getting Started
1. Clone the Repository
git clone https://github.com/Prem-Development/gs_app.git
2. Open the Project
cd gs_app
3. Install Dependencies
flutter pub get
4. Check Flutter Environment
flutter doctor
5. Run the Application

Connect an Android device or start an Android emulator and run:

flutter run
📦 Build APK

To generate a release APK:

flutter build apk --release

The generated APK can be found inside:

build/app/outputs/flutter-apk/release/
🧪 Testing

The application can be tested using:

Android physical devices
Android Emulator

Testing should cover:

Citizen registration
NIC search
Citizen editing
Citizen deletion
Image capture
Gallery selection
PDF generation
PDF printing
Backup
Restore
Language switching
Dynamic fields
Offline functionality
📂 Project Structure
gs_app/
│
├── android/
├── assets/
│   └── images/
│
├── lib/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── database/
│   ├── widgets/
│   └── main.dart
│
├── test/
│
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── .gitignore

The exact folder structure may change as the project develops.

🖥️ Main Functional Modules
Dashboard
    │
    ├── Citizen Management
    │      ├── Add Citizen
    │      ├── View Citizen
    │      ├── Edit Citizen
    │      └── Delete Citizen
    │
    ├── Search
    │      ├── NIC Search
    │      └── Filter Search
    │
    ├── Images
    │      ├── Camera
    │      └── Gallery
    │
    ├── Reports
    │      ├── Full PDF
    │      └── Filtered PDF
    │
    ├── Backup
    │      ├── Create Backup
    │      └── Restore Backup
    │
    └── Settings
           └── Tamil / English
🌐 Offline Architecture
        Android Device
              │
              ▼
       Flutter Application
              │
       ┌──────┴──────┐
       │             │
       ▼             ▼
    Provider       SQLite
       │             │
       │       Citizen Data
       │
       ▼
   Application UI
       │
   ┌───┴────┐
   │        │
   ▼        ▼
 Images    PDF
   │
   ▼
Local Storage

No internet connection is required for the core functionality.

📸 Screenshots

Screenshots can be added here as the project UI is completed.

Example:

![Dashboard](screenshots/dashboard.png)

![Citizen List](screenshots/citizen_list.png)

![Citizen Details](screenshots/citizen_details.png)

![Search](screenshots/search.png)
🔮 Future Improvements

Possible future improvements include:

Advanced reporting
More customizable fields
Improved backup management
Database encryption
Advanced local security
More language support
Improved accessibility
Advanced filtering
Automatic backup reminders
Improved PDF templates
Role-based access if required in a future version
⚠️ Important Note

This project is intended as an educational and practical software development project for digital citizen record management.

Because the application can store sensitive citizen information, proper security, device protection, backup protection, and applicable government/privacy requirements should be considered before real-world deployment.

👨‍💻 Developer

Premmakkumar

Flutter & Android Developer

GitHub:

https://github.com/Prem-Development

📄 License

This project is currently intended for educational and development purposes.

A suitable open-source license can be added when the project is ready for public distribution.

⭐ Support

If you find this project useful, consider giving the repository a ⭐ on GitHub.

🇱🇰 GS Citizen Management System

Digital • Offline • Secure • Simple

Built with ❤️ using Flutter & Dart.
