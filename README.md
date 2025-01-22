# 🎮 MCSM (Minecraft Server Manager)
> A modern Minecraft server manager built with Flutter and Dart.

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg) ![License](https://img.shields.io/badge/license-AGPL--3.0-green.svg) ![Flutter](https://img.shields.io/badge/flutter-3.0%2B-blue.svg) ![Dart](https://img.shields.io/badge/dart-3.0%2B-blue.svg)

## ✨ Features
- 🚀 Native desktop interface with Flutter
- 🔒 Secure Minecraft server management
- 💾 Efficient system resource management
- 🎯 Cross-platform support (Windows, macOS, Linux)
- 🔄 Real-time server monitoring and management
- 📊 Integrated console
- 🔌 Support for Vanilla and Paper servers
- 💻 Complete server lifecycle management

## 🛠️ Tech Stack
- **Framework**: Flutter Desktop
- **Language**: Dart
- **State Management**: Riverpod
- **UI Components**: Material Design
- **Window Management**: window_manager
- **File Management**: file_picker

## 📋 Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Java Runtime Environment (JRE) 17+

## 🚀 Getting Started
1. **Clone the repository**
```bash
git clone https://github.com/Pyro18/mcsm.git
cd mcsm
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Development**
```bash
flutter run -d windows # or linux/macos
```

4. **Build**
```bash
flutter build windows # or linux/macos
```

## 📁 Project Structure
```
mcsm/
├── lib/
│   ├── screens/      # Application screens
│   ├── widgets/      # Reusable widgets
│   ├── services/     # Services and business logic
│   ├── models/       # Data models
│   └── utils/        # Utilities and helpers
├── assets/          # Static assets
└── test/           # Test files
```

## 🔧 Configuration
The application can be configured through the user interface or by editing configuration files:
- `config.json`: General application settings
- `servers.json`: Server configurations
- `java-settings.json`: Java runtime settings

## 📝 License
This project is licensed under GNU AGPL-3.0 with Commons Clause - see the [LICENSE](LICENSE) file for details.

Key points:
- Source code must remain open source
- Modifications must be shared under the same license
- Commercial use is restricted and requires explicit permission from the author
- You can use the software for personal and non-commercial purposes

## 🤝 Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.

## 🔜 Roadmap
- [ ] Server backup system
- [ ] Plugin management
- [ ] Server templates
- [ ] Multi-language support
- [ ] Notification system
- [ ] Resource monitoring
- [ ] Plugin management

## 💬 Support
- GitHub Issues: For bug reports and feature requests
- Discussions: For questions and community support

## 📜 Legal
- MCSM (Minecraft Server Manager)
- Copyright (C) 2024 Marius Noroaca (Pyro18)
- Licensed under GNU AGPL-3.0 with Commons Clause

---
Built with ❤️ using Flutter and Dart
