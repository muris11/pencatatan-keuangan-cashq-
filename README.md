# casq1

A modern Flutter project for authentication and image display.

<img src="assets/images/1.jpg" alt="Sample Image" width="150" />

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Usage Example](#usage-example)
- [Displaying Images in README (GitHub)](#displaying-images-in-readme-github)
- [Folder Structure](#folder-structure)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Resources](#resources)

## Project Overview

This app demonstrates user authentication (email/password, Google Sign-In) and displays images from local assets. Built with Firebase and Google Sign-In integration. Suitable for personal finance tracking and image gallery features.

## Features

- User registration with email verification
- Login with email/password
- Google Sign-In
- Password reset
- Logout
- Display images from assets/images (1.jpg - 8.jpg)
- Responsive UI
- Firebase integration

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Firebase account](https://firebase.google.com/)
- Git

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/muris11/pencatatan-keuangan-cashq-.git
   cd pencatatan-keuangan-cashq-
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Firebase setup:**
   - Configure Firebase for your app (Android/iOS/Web)
   - Add `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) to respective folders
   - Enable Email/Password and Google authentication in Firebase Console
4. **Add images:**
   Place images named `1.jpg` to `8.jpg` in:
   ```
   assets/images/
   ```
5. **Update pubspec.yaml:**
   Ensure assets are listed:
   ```yaml
   flutter:
     assets:
       - assets/images/1.jpg
       - assets/images/2.jpg
       - assets/images/3.jpg
       - assets/images/4.jpg
       - assets/images/5.jpg
       - assets/images/6.jpg
       - assets/images/7.jpg
       - assets/images/8.jpg
   ```
6. **Run the app:**
   ```bash
   flutter run
   ```

## Usage Example

To display an image from assets in your Flutter app:

```dart
Image.asset('assets/images/1.jpg')
```

## Displaying Images in README (GitHub)

To show images in your README on GitHub, use Markdown syntax:

```markdown
![Description](relative/path/to/image.jpg)
```

Example:

```markdown
![Sample Image](assets/images/1.jpg)
```

> Note: Images will only show on GitHub if they are committed and pushed to the repository.

## Folder Structure

```
c:/Users/rifqy/Documents/flutterprojects/casq1/
├── assets/
│   └── images/
│       ├── 1.jpg
│       ├── 2.jpg
│       ├── 3.jpg
│       ├── 4.jpg
│       ├── 5.jpg
│       ├── 6.jpg
│       ├── 7.jpg
│       └── 8.jpg
├── lib/
│   └── services/
│       └── auth_service.dart
│   └── ...
├── pubspec.yaml
└── README.md
```

## Contributing

Contributions are welcome! Please open issues or submit pull requests for improvements and bug fixes.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Contact

For questions or feedback, contact:

- Rifqy (GitHub: [muris11](https://github.com/muris11))

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

---

Developed by Rifqy. Powered by Flutter & Firebase.
