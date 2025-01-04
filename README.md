# 🎮 MCSM (Minecraft Server Manager)

> A user-friendly desktop application to manage Minecraft servers, designed to simplify the process of creating, configuring, and maintaining Minecraft servers.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg) ![License](https://img.shields.io/badge/license-MIT-green.svg) ![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg) ![.NET](https://img.shields.io/badge/.NET-9.0-purple.svg) ![Status](https://img.shields.io/badge/status-alpha-orange.svg)


## 📑 Table of Contents
- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Usage](#-usage)
  - [Starting a Server](#-starting-a-server)
  - [Server Management](#️-server-management)
  - [Configuration Options](#️-configuration-options)
- [Project Structure](#-project-structure)
- [Development](#-development)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)
- [Support](#-support)
- [Roadmap](#️-roadmap)
- [Troubleshooting](#-troubleshooting)


## ✨ Features

- 🚀 Easy server setup and configuration
- 📊 Real-time server monitoring
- 💻 Integrated console with command support
- 💾 Automated backup system
- 🔌 Plugin management
- 📈 Server performance monitoring
- 🎯 User-friendly interface
- 🔄 Multi-version support

## 📋 Requirements

- 🪟 Windows OS
- 🔷 .NET 9.0 or higher
- ☕ Java Runtime Environment (JRE) 17 or higher
- 💾 Minimum 4GB RAM recommended

## 📥 Installation

1. 📦 Download the latest release from the releases page
2. 📂 Extract the files to your desired location
3. ▶️ Run MCSM.Desktop.exe
4. ⚙️ First-time setup will guide you through the Java path configuration

## 🎮 Usage

### 🚀 Starting a Server

1. ⚙️ Click "Configure" to set up your server properties
2. 📋 Select your desired Minecraft version
3. 🔧 Configure memory allocation and other settings
4. ▶️ Click "Start Server" to launch

### 🛠️ Server Management

- 💻 Use the integrated console to input commands
- 📊 Monitor server status in real-time
- 👥 View connected players and server performance
- 📝 Access logs and backup options

### ⚙️ Configuration Options

- 🎮 Server Properties
  - 💾 Memory allocation (Min/Max)
  - 🔌 Server port
  - 💬 MOTD (Message of the Day)
  - 🎲 Gamemode
  - 📊 Difficulty
  - 👥 Max players

- 🔧 Application Settings
  - 🚀 Auto-start options
  - 💾 Backup intervals
  - 📝 Logging preferences
  - 🎨 UI customization

## 📁 Project Structure

```
MCSM/
├── MCSM.Core/            # Core functionality
│   ├── Models/          # Data models
│   ├── Services/        # Business logic
│   └── Utils/          # Utility classes
└── MCSM.Desktop/        # UI implementation
    ├── Forms/          # Windows Forms
    ├── Controls/       # Custom controls
    └── assets/         # Resources
```

## 👨‍💻 Development

### 🛠️ Building from Source

1. 📥 Clone the repository
```bash
git clone https://github.com/Pyro18/MCSM.git
```

2. 📂 Open the solution in Visual Studio or Rider

3. 📦 Restore NuGet packages

4. 🔨 Build the solution
```bash
dotnet build
```

### 🤝 Contributing

1. 🔱 Fork the repository
2. 🌿 Create a feature branch
3. 💾 Commit your changes
4. 🚀 Push to the branch
5. 📝 Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👏 Acknowledgments

- 🎮 Minecraft® is a registered trademark of Mojang Studios
- ⚠️ This project is not affiliated with Mojang Studios or Microsoft

## 🆘 Support

For support, please:
- 🐛 Open an issue in the GitHub repository
- 📚 Check the Wiki for common solutions
- 💬 Join our Discord community (coming soon)

## 🗺️ Roadmap

- [ ] 🌍 Multi-language support
- [ ] 📋 Server templates
- [ ] 🔌 Plugin marketplace integration
- [ ] 💾 Advanced backup management
- [ ] 📊 Server statistics and analytics
- [ ] 🌐 Remote management capabilities
- [ ] 📚 Comprehensive Wiki documentation
  - [ ] Installation guides
  - [ ] Configuration tutorials
  - [ ] Plugin management
  - [ ] Advanced troubleshooting
  - [ ] Developer documentation

## 🔧 Troubleshooting

### Common Issues

<details>
<summary>🚫 Server Won't Start</summary>

### Possible Causes:
1. **Java Installation Issues**
   - Java not installed
   - Incorrect Java version
   - Java path not properly configured

### Solutions:
1. Verify Java installation:
   ```bash
   java -version
   ```
2. Check Java path in MCSM settings
3. Install appropriate Java version (JRE 17+ recommended)
4. Ensure proper environment variables

### Prevention:
- Keep Java updated
- Use MCSM's Java path configuration tool
- Monitor Java version compatibility
</details>

<details>
<summary>⚠️ Performance Issues</summary>

### Symptoms:
- Server lag
- High memory usage
- Slow response times

### Solutions:
1. **Memory Management**
   - Adjust allocated RAM
   - Monitor usage patterns
   - Clean up unused worlds

2. **Performance Optimization**
   - Update server software
   - Optimize world settings
   - Review installed plugins

### Best Practices:
- Regular monitoring
- Scheduled restarts
- Performance logging
</details>

<details>
<summary>🔌 Plugin Problems</summary>

### Common Issues:
1. **Compatibility**
   - Version mismatch
   - Conflicting plugins
   - Missing dependencies

### Troubleshooting Steps:
1. Check plugin version compatibility
2. Review server logs for errors
3. Verify dependencies are installed
4. Test plugins in isolation

### Prevention:
- Regular plugin updates
- Maintain plugin documentation
- Test in staging environment
</details>

<details>
<summary>🌐 Network Issues</summary>

### Common Problems:
1. **Connection Issues**
   - Port forwarding
   - Firewall blocking
   - IP configuration

### Solutions:
1. Verify port forwarding setup
2. Check firewall settings
3. Confirm server IP configuration
4. Test network connectivity

### Network Setup Guide:
- Configure router settings
- Set up port forwarding
- Configure server properties
</details>

<details>
<summary>💾 Backup and Data Issues</summary>

### Types of Problems:
1. **Backup Failures**
   - Storage space
   - Permission issues
   - Corrupted backups

### Resolution Steps:
1. Check available disk space
2. Verify backup permissions
3. Test backup integrity
4. Configure automatic cleanup

### Best Practices:
- Regular backup testing
- Automated backup verification
- Multiple backup locations
</details>
