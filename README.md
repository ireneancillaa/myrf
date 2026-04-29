# MYRF - Broiler Farm Monitoring System

MYRF is a comprehensive, real-time Flutter application designed to digitize and streamline data collection, monitoring, and analysis for broiler chicken farm operations. It replaces manual paperwork with an intuitive, dynamic mobile interface backed by Firebase.

## 🌟 Key Features

- **End-to-End Project Management**: Plan and manage broiler projects through distinct workflow stages (Drafted, In Progress, Completed).
- **Comprehensive Monitoring Modules**:
  - **Infeed**: Track daily feed intake dynamically.
  - **Depletion**: Record mortality and culling with dynamic pen constraints.
  - **Weighing**: Capture and calculate body weight metrics.
  - **Male Birds**: Specialized monitoring for male broilers.
  - **Feces Score**: Detailed health checks and visual health scoring.
- **Real-Time Configuration Sync**: Core operational data (like Strains, Hatcheries, and Trial Houses) are streamed directly from Firestore in real-time, instantly reflecting administrative updates across the app.
- **Dynamic Pen Mapping**: Automatically adapts UI constraints based on the specific `penTrialhouse` capacity of the selected facility.
- **Bluetooth IoT Integration**: Seamlessly connect to Bluetooth weighing scales via `flutter_blue_plus` for automated, error-free data entry.
- **Offline-First & Draft Capabilities**: Robust drafting system that saves local progress before pushing deterministic, timestamp-based records to Firestore.
- **Smart Data Persistence**: Inline Base64 image compression to store attachments securely within Firestore's limits, eliminating complex Storage permission issues.
- **PDF Generation**: Native support for generating and sharing comprehensive PDF reports of project data.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [GetX](https://pub.dev/packages/get) (Reactive State Management, Dependency Injection, and Routing)
- **Backend as a Service (BaaS)**: [Firebase](https://firebase.google.com/)
  - **Cloud Firestore**: Real-time NoSQL database
  - **Firebase Auth**: Secure user authentication
- **Key Packages**:
  - `flutter_blue_plus`: For Bluetooth low energy hardware integration.
  - `pdf` & `printing`: Document generation and layout formatting.
  - `image_picker`: Camera and gallery attachments.

## 📂 Project Structure

```text
lib/
├── bindings/       # GetX bindings for dependency injection
├── controller/     # Business logic and reactive state controllers
├── models/         # Dart data classes and Firestore serialization
├── pages/          # UI Screens (Broiler, Monitoring, Login, Home)
├── services/       # External services (Firestore, PDF, Bluetooth)
└── widgets/        # Reusable UI components
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (`^3.11.0` or newer)
- Dart SDK
- Firebase Project (configured for Android/iOS)

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/myrf.git
   cd myrf
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Add your `google-services.json` to `android/app/`.
   - Add your `GoogleService-Info.plist` to `ios/Runner/` (if deploying to iOS).
   - Ensure your Firestore Security Rules are configured to allow appropriate scoped read/writes.

4. **Run the App:**
   ```bash
   flutter run
   ```

## 📝 License
This project is proprietary and intended for internal farm monitoring and research use.
