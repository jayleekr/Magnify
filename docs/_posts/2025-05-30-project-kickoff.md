---
layout: post
title: "🚀 Magnify Project Launch - First Steps in Building a ZoomIt Alternative macOS App"
date: 2025-05-30 09:00:00 +0900
category: "Project Planning"
description: "Starting the development project to create a macOS native screen annotation tool that provides equivalent functionality to Windows ZoomIt, developed in Swift for Mac App Store release and monetization"
tags: [project-launch, macOS, Swift, ZoomIt, app-development]
milestone: 1
checkpoint: 1
author: "Jay Lee"
---

## 🔍 Project Genesis

When presenting or teaching on macOS, there are frequent occasions where we need to magnify parts of the screen or draw annotations for explanation. While Windows has an excellent tool called **ZoomIt** by Microsoft, macOS lacks native apps of equivalent quality.

This project was born from the following needs:

- **Presentation Efficiency:** When you want to magnify specific parts of the screen
- **Real-time Annotation:** When you want to draw directly on the screen for explanation
- **Time Management:** When you want to track presentation time
- **macOS Native Experience:** When you want to maximize macOS performance and usability

## 📋 Project Preparation Process

Before diving into actual development, thorough planning and preparation were necessary. Over the past few days, the following preparatory work was completed:

### 1. ZoomIt Feature Analysis
Analyzed all features of Windows ZoomIt and documented features implementable in the macOS environment.

### 2. macOS Development Guide Research
Conducted detailed research on technology stacks, constraints, and App Store deployment strategies for macOS app development.

### 3. Technology Stack Selection
Decided on the Swift + AppKit + ScreenCaptureKit combination to provide optimal performance and user experience.

### 4. Project Structure Design
Established a detailed development plan consisting of 5 milestones and 20 checkpoints.

### 5. GitHub Repository and Pages Setup
Built infrastructure for version control and development process documentation.

## 🛠️ Technology Stack Selection

To provide the best performance and user experience as a macOS native app, the following technology stack was selected:

| Technology | Purpose | Selection Reason |
|------------|---------|------------------|
| **Swift 5.9+** | Main development language | Write safe and efficient code using latest Swift features |
| **AppKit** | UI framework | macOS native UI, transparent overlays and complex window management |
| **ScreenCaptureKit** | Screen capture | Latest screen capture API for macOS 12.3+, high performance and security |
| **Metal** | GPU acceleration | Real-time screen magnification/zoom processing for smooth user experience |
| **Carbon** | Global hotkeys | Support for App Sandbox environment through RegisterEventHotKey |
| **SwiftUI** | Settings UI | Modern and intuitive settings interface |

## 📅 Development Plan

Development will proceed over 9 weeks (56 days) divided into 5 major milestones:

### Milestone 1: Core Infrastructure (Week 1-2)
- ✅ Checkpoint 1.1: Xcode project setup and App Sandbox configuration
- ⏳ Checkpoint 1.2: ScreenCaptureKit permissions and basic screen capture
- ⏳ Checkpoint 1.3: Transparent overlay NSWindow system
- ⏳ Checkpoint 1.4: Unit testing and GitHub Actions CI/CD

### Milestone 2: Zoom & Annotation Core (Week 3-4)
- ⏳ Checkpoint 2.1: Real-time screen magnification/zoom engine
- ⏳ Checkpoint 2.2: NSBezierPath-based pen drawing system
- ⏳ Checkpoint 2.3: Carbon RegisterEventHotKey global shortcuts
- ⏳ Checkpoint 2.4: Basic user interface

### Milestone 3: Advanced Features (Week 5-6)
- ⏳ Checkpoint 3.1: NSTextField text annotation system
- ⏳ Checkpoint 3.2: Presentation timer and alarm
- ⏳ Checkpoint 3.3: SwiftUI hybrid settings UI
- ⏳ Checkpoint 3.4: Various pen tools and color system

### Milestone 4: Polish & Testing (Week 7-8)
- ⏳ Checkpoint 4.1: Performance optimization (Memory <50MB, Response <100ms)
- ⏳ Checkpoint 4.2: Comprehensive testing (XCTest, XCUITest)
- ⏳ Checkpoint 4.3: TestFlight beta testing
- ⏳ Checkpoint 4.4: App Store metadata and marketing materials

### Milestone 5: App Store Launch (Week 9)
- ⏳ Checkpoint 5.1: Apple Distribution code signing
- ⏳ Checkpoint 5.2: App Store Connect upload
- ⏳ Checkpoint 5.3: Apple review response
- ⏳ Checkpoint 5.4: Official launch and marketing

## 🎯 Core Feature Design

Magnify will provide the following core features:

> **🔍 Real-time Screen Magnification:** Provides smooth magnification/zoom centered on mouse position, targeting response times under 100ms through Metal GPU acceleration.

> **✏️ Real-time Annotation Drawing:** Provides smooth pen drawing using NSBezierPath with various color and thickness options.

> **📝 Text Annotations:** Ability to add and edit text at any position on the screen.

> **⏱️ Presentation Timer:** Countdown/count-up timer and visual alarms to help with time management.

> **⌨️ Global Hotkeys:** Global shortcuts that work in App Sandbox environment, allowing quick feature activation from any app.

## 📊 Performance Goals

The following performance targets were set for user experience:

```
Zoom Response Time: <100ms
Memory Usage: <50MB
CPU Usage: <30% during real-time drawing
Crash Rate: <0.1%
Test Coverage: 80%+
```

## 🚀 Development Methodology

This project applies the following development methodologies:

### Checkpoint-Based Development
Each milestone is divided into 4 checkpoints, completing and documenting specific deliverables every 2-3 days.

### Continuous Documentation
Upon completion of each checkpoint, detailed records of the development process, challenges, and solutions are documented on GitHub Pages.

### AI-Accelerated Development
Detailed AI development prompts are prepared for each milestone to enable efficient development.

### GitHub-Based Collaboration
All code is managed on GitHub, with automated build/test/deploy implemented through Actions.

## 💰 Monetization Strategy

A phased monetization strategy was established for sustainable app development:

- **Phase 1 (Post-launch):** Free distribution to acquire users and collect feedback
- **Phase 2 (3 months later):** Add in-app purchases for premium features ($2.99-$4.99)
- **Phase 3 (6 months later):** Transition to paid app for new users ($9.99-$14.99)

## 🔮 Next Steps

All preparations are now complete! The next post will cover the first checkpoint: **"Xcode Project Setup and App Sandbox Configuration"** in detail.

Looking forward to the 9-week development journey ahead. Let's build the best screen annotation tool for macOS that surpasses ZoomIt! 🚀

---

**📍 Current Progress:** Project planning completed, GitHub Pages setup completed  
**⏭️ Next Checkpoint:** Checkpoint 1.1 - Xcode Project Setup (Day 1-2) 