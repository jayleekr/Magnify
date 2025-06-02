# 🔍 Magnify - macOS Screen Annotation Tool

> **ZoomIt for macOS** - Screen annotation tool for presentations and lectures

[![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/swift/)
[![macOS](https://img.shields.io/badge/macOS-12.3+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live-brightgreen?style=for-the-badge&logo=github)](https://jayleekr.github.io/Magnify/)

## 🎯 Project Overview

**Magnify** is a screen annotation tool for presentations and lectures on macOS. It implements performance and usability of a macOS native app while providing equivalent functionality to Windows ZoomIt.

### ✨ Core Features

- 🔍 **Real-time Screen Magnification** - Smooth zoom centered on mouse position
- ✏️ **Pen Tool Annotation Drawing** - Support for various colors and thickness
- 📝 **Text Annotations** - Add text at any position on screen
- ⏱️ **Presentation Timer** - Countdown/count-up timer with alarms
- ⌨️ **Global Shortcuts** - Quick feature activation from any app
- 🎨 **Various Tools** - Highlighter, eraser, shape drawing

## 🛠️ Tech Stack

| Technology | Purpose | Version |
|------------|---------|---------|
| **Swift** | Main development language | 5.9+ |
| **AppKit** | UI framework | macOS 12.3+ |
| **ScreenCaptureKit** | Screen capture | macOS 12.3+ |
| **Metal** | GPU acceleration | - |
| **Carbon** | Global shortcuts | - |
| **SwiftUI** | Settings UI | - |

## 📊 Project Status

| Milestone | Status | Progress |
|-----------|--------|----------|
| **Milestone 1: Core Infrastructure** | ✅ Complete | 100% |
| **Milestone 2: Zoom & Annotation** | ✅ Complete | 100% |
| **Milestone 3: Advanced Features** | 🚧 In Progress | 33% |
| **Milestone 4: Polish & Testing** | ⏳ Pending | 0% |
| **Milestone 5: App Store Launch** | ⏳ Pending | 0% |

### 📊 Checkpoint Progress

#### Milestone 1: Core Infrastructure ✅ COMPLETED
- [x] **Checkpoint 1.1:** ✅ Xcode project setup (COMPLETED)
- [x] **Checkpoint 1.2:** ✅ ScreenCaptureKit implementation (COMPLETED)
- [x] **Checkpoint 1.3:** ✅ Transparent overlay window system (COMPLETED)
- [x] **Checkpoint 1.4:** ✅ Global hotkey implementation (COMPLETED)
- [x] **Checkpoint 1.5:** ✅ Settings and preferences system (COMPLETED)

#### Milestone 2: Zoom & Annotation ✅ COMPLETED
- [x] **Checkpoint 2.1:** ✅ Zoom system implementation (COMPLETED)
- [x] **Checkpoint 2.2:** ✅ Advanced drawing tools (COMPLETED)
- [x] **Checkpoint 2.3:** ✅ Annotation management (COMPLETED)

#### Milestone 3: Advanced Features 🚧 IN PROGRESS
- [x] **Checkpoint 3.1:** ✅ Screen recording system (COMPLETED)
- [ ] **Checkpoint 3.2:** 🚧 Break timer and presentation tools (IN PROGRESS)
- [ ] **Checkpoint 3.3:** ⏳ Advanced annotation features (PLANNED)

#### Latest Achievement: Checkpoint 3.1 Complete! 🎉
- Implemented comprehensive screen recording system with AVFoundation + ScreenCaptureKit
- Added professional SwiftUI recording interface with real-time controls
- Created multi-format video export (MP4, MOV, AVI) with quality settings
- Enhanced annotation overlay integration for recording
- Built extensive test coverage and performance optimization

#### Currently Working: Checkpoint 3.2 - Break Timer & Presentation Tools 🚧
- Implementing comprehensive presentation timer system
- Adding break timer functionality for productivity workflows
- Creating timer overlay UI with professional SwiftUI interface
- Building alarm notifications and warning system

**Current Project Status: 80% Complete**

**📖 [Read the full progress blog post →](https://jayleekr.github.io/Magnify/)**

## 📖 Development Blog

Check out the real-time development process and technical challenges on GitHub Pages:

🔗 **[Magnify Development Blog](https://jayleekr.github.io/Magnify/)**

### 📝 Recent Posts
- [🚀 Magnify Project Launch - First Steps in Building a ZoomIt Alternative macOS App](https://jayleekr.github.io/Magnify/blog/)

## 🎯 Performance Goals

| Metric | Target | Current Status |
|--------|--------|----------------|
| Zoom response time | < 100ms | - |
| Memory usage | < 50MB | - |
| CPU usage | < 30% (during drawing) | - |
| Crash rate | < 0.1% | - |
| Test coverage | 80%+ | - |

## 🚀 Local Development Setup

### Requirements
- macOS 12.3 or later
- Xcode 16 or later
- Swift 5.9 or later
- Apple Developer Program account (for App Store distribution)

### Development Environment Setup
```bash
# Clone repository
git clone https://github.com/jayleekr/Magnify.git
cd Magnify

# Install GitHub CLI (optional)
brew install gh

# Check development progress
gh workflow list
gh run list --limit 5
```

## 📱 App Store Launch Plan

### Monetization Strategy
- **Phase 1:** Free distribution (user acquisition)
- **Phase 2:** Add in-app purchases ($2.99-$4.99)
- **Phase 3:** Paid app conversion ($9.99-$14.99)

### Distribution Info
- **Bundle ID:** `com.jayleekr.magnify`
- **App Store Name:** Magnify - Screen Annotation Tool
- **Target:** macOS 12.3+
- **Category:** Productivity

## 🤝 Contributing

This project is currently being developed as a personal project. The development process and results are shared in real-time on GitHub Pages.

### Feedback and Suggestions
- 🐛 **Bug Reports:** [Issues](https://github.com/jayleekr/Magnify/issues)
- 💡 **Feature Suggestions:** [Discussions](https://github.com/jayleekr/Magnify/discussions)
- 📧 **Contact:** [GitHub Profile](https://github.com/jayleekr)

## 📄 License

This project is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🔗 Related Links

- 📱 **GitHub Repository:** https://github.com/jayleekr/Magnify
- 📖 **Development Blog:** https://jayleekr.github.io/Magnify/
- 🛠️ **Project Configuration:** [project_config.md](project_config.md)
- 🤖 **AI Development Prompts:** [ai_development_prompts.md](ai_development_prompts.md)

---

<div align="center">

**🚀 Magnify - macOS Screen Annotation Tool Development Project**

Built with ❤️ using Swift, AppKit, and modern macOS technologies

© 2025 Jay Lee

</div>
