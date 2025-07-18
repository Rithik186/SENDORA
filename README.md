# Sendora

Sendora is a cross-platform Flutter application for secure and efficient file sharing, conversion, and compression. It leverages Firebase for authentication and storage, and supports online file transfers.

## Features

- **Send Files Online:** Upload files to the cloud and share download links.
- **File Conversion:** Convert images (JPG/PNG) and text to PDF, and between image formats.
- **File Compression:** Compress images and PDFs to save space.
- **User Authentication:** Sign up, sign in, and manage your profile with Firebase Auth and Google Sign-In.

## Screenshots
<!-- Add screenshots of your app here if available -->

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase CLI](https://firebase.google.com/docs/cli) and a Firebase project
- Platform-specific setup for [Android](https://firebase.google.com/docs/flutter/setup?platform=android) and [iOS](https://firebase.google.com/docs/flutter/setup?platform=ios)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/sendora.git
   cd sendora
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.
   - Update `firebase_options.dart` if needed.
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure
- `lib/` - Main application code
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` - Platform-specific code
- `assets/` - Images and other assets

## Contributing
Contributions are welcome! Please open issues and submit pull requests for new features, bug fixes, or improvements.

## License
[MIT](LICENSE) (or specify your license here)

## Acknowledgements
- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Other libraries used](pubspec.yaml)
