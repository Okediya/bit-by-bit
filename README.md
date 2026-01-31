# Bit by Bit 🤖

A minimalist, powerful AI chat application built with Flutter. Bit by Bit helps you break down complex topics using focused sub-conversations.

## ✨ Key Features

- **Branching Conversations:** Highlight any part of an AI response to create a "sub-conversation" focused specifically on that context.
- **Tree-View History:** Visualize your conversation threads in a hierarchical tree structure, allowing for infinite nesting of topics.
- **Multi-Provider Support:** Bring your own API keys for:
  - Google Gemini
  - Groq (Llama, Mixtral)
  - OpenAI (GPT-4)
  - Anthropic (Claude)
- **Minimalist Design:** A distraction-free, black-and-white aesthetic designed for focus.
- **Local Data:** All your chats and API keys are stored locally on your device.

## 📱 Screenshots

<!-- Add your screenshots here -->

## 🛠️ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0.0 or higher)
- [Dart SDK](https://dart.dev/get-dart)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/bit-by-bit.git
   cd bit-by-bit
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Run on Chrome
   flutter run -d chrome

   # Run on Windows
   flutter run -d windows

   # Run on Android
   flutter run -d android
   ```

## 📦 Building for Release

To build the application for distribution:

### Android (APK)
```bash
flutter build apk --release
```
The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

### Windows (.exe)
```bash
flutter build windows --release
```
The executable will be located at `build/windows/runner/Release/`.

## 🏗️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Local Storage:** [SharedPreferences](https://pub.dev/packages/shared_preferences)
- **AI Integration:** [Google Generative AI](https://pub.dev/packages/google_generative_ai), HTTP
- **UI:** Custom minimalist theme, [Flutter Animate](https://pub.dev/packages/flutter_animate)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
