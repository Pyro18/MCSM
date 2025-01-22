# 🎮 MCSM (Minecraft Server Manager)
> Un moderno gestore di server Minecraft costruito con Flutter e Dart.

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg) ![License](https://img.shields.io/badge/license-MIT-green.svg) ![Flutter](https://img.shields.io/badge/flutter-3.0%2B-blue.svg) ![Dart](https://img.shields.io/badge/dart-3.0%2B-blue.svg)

## ✨ Features
- 🚀 Interfaccia desktop nativa con Flutter
- 🔒 Gestione sicura dei server Minecraft
- 💾 Gestione efficiente delle risorse di sistema
- 🎯 Supporto cross-platform (Windows, macOS, Linux)
- 🔄 Gestione server con monitoraggio in tempo reale
- 📊 Console integrata
- 🔌 Supporto per server Vanilla e Paper
- 💻 Gestione completa del ciclo di vita del server

## 🛠️ Tech Stack
- **Framework**: Flutter Desktop
- **Linguaggio**: Dart
- **State Management**: Riverpod
- **UI Components**: Material Design
- **Window Management**: window_manager
- **File Management**: file_picker

## 📋 Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Java Runtime Environment (JRE) 17+

## 🚀 Getting Started
1. **Clona il repository**
```bash
git clone https://github.com/Pyro18/mcsm.git
cd mcsm
```

2. **Installa le dipendenze**
```bash
flutter pub get
```

3. **Sviluppo**
```bash
flutter run -d windows # o linux/macos
```

4. **Build**
```bash
flutter build windows # o linux/macos
```

## 📁 Project Structure
```
mcsm/
├── lib/
│   ├── screens/      # Schermate dell'applicazione
│   ├── widgets/      # Widget riutilizzabili
│   ├── services/     # Servizi e logica di business
│   ├── models/       # Modelli dati
│   └── utils/        # Utilità e helpers
├── assets/          # Risorse statiche
└── test/           # Test files
```

## 🔧 Configuration
L'applicazione può essere configurata attraverso l'interfaccia utente o modificando i file di configurazione:
- `config.json`: Impostazioni generali dell'applicazione
- `servers.json`: Configurazioni dei server
- `java-settings.json`: Impostazioni runtime Java

## 🤝 Contributing
1. Fai il fork del repository
2. Crea un nuovo branch per la feature
3. Fai le tue modifiche
4. Invia una pull request

## 🔜 Roadmap
- [ ] Sistema di backup dei server
- [ ] Integrazione gestione mod
- [ ] Templates per server
- [ ] Supporto multi-lingua
- [ ] Sistema di notifiche
- [ ] Monitoraggio risorse
- [ ] Gestione plugin

## 💬 Support
- GitHub Issues: Per bug report e richieste di feature
- Discussions: Per domande e supporto della community

---
Built with ❤️ using Flutter and Dart