# 🔍 Magnify - macOS Screen Annotation Tool

> **ZoomIt for macOS** - 프레젠테이션과 강의를 위한 화면 주석 도구

[![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/swift/)
[![macOS](https://img.shields.io/badge/macOS-12.3+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live-brightgreen?style=for-the-badge&logo=github)](https://jayleekr.github.io/Magnify/)

## 🎯 프로젝트 개요

**Magnify**는 macOS에서 프레젠테이션과 강의용으로 사용할 수 있는 화면 주석 도구입니다. Windows ZoomIt과 동등한 기능을 제공하면서 macOS 네이티브 앱의 성능과 사용성을 구현합니다.

### ✨ 핵심 기능

- 🔍 **실시간 화면 확대/축소** - 마우스 위치 기준 부드러운 줌
- ✏️ **펜 도구로 주석 그리기** - 다양한 색상과 굵기 지원
- 📝 **텍스트 주석** - 화면 위 임의 위치에 텍스트 추가
- ⏱️ **프레젠테이션 타이머** - 카운트다운/업 타이머와 알람
- ⌨️ **전역 단축키** - 어떤 앱에서든 빠른 기능 활성화
- 🎨 **다양한 도구** - 하이라이터, 지우개, 도형 그리기

## 🛠️ 기술 스택

| 기술 | 용도 | 버전 |
|------|------|------|
| **Swift** | 주 개발 언어 | 5.9+ |
| **AppKit** | UI 프레임워크 | macOS 12.3+ |
| **ScreenCaptureKit** | 화면 캡처 | macOS 12.3+ |
| **Metal** | GPU 가속 | - |
| **Carbon** | 전역 단축키 | - |
| **SwiftUI** | 설정 UI | - |

## 📅 개발 진행상황

### 🚀 Current Status: 프로젝트 초기화 및 GitHub Pages 설정 완료

| 마일스톤 | 기간 | 상태 | 진행률 |
|----------|------|------|--------|
| **Milestone 1: Core Infrastructure** | Week 1-2 | ⏳ Pending | 0% |
| **Milestone 2: Zoom & Annotation** | Week 3-4 | ⏳ Pending | 0% |
| **Milestone 3: Advanced Features** | Week 5-6 | ⏳ Pending | 0% |
| **Milestone 4: Polish & Testing** | Week 7-8 | ⏳ Pending | 0% |
| **Milestone 5: App Store Launch** | Week 9 | ⏳ Pending | 0% |

### 📊 체크포인트 진행상황

#### Milestone 1: Core Infrastructure
- [ ] **Checkpoint 1.1:** Xcode 프로젝트 설정 (Day 1-2)
- [ ] **Checkpoint 1.2:** ScreenCaptureKit 구현 (Day 3-4)
- [ ] **Checkpoint 1.3:** 투명 오버레이 NSWindow (Day 5-7)
- [ ] **Checkpoint 1.4:** 단위 테스트 및 CI (Day 8-10)

## 📖 개발 블로그

실시간 개발 과정과 기술적 도전과제들을 GitHub Pages에서 확인하세요:

🔗 **[Magnify Development Blog](https://jayleekr.github.io/Magnify/)**

### 📝 최근 포스트
- [🚀 Magnify 프로젝트 시작 - ZoomIt 대안 macOS 앱 개발 여정의 첫걸음](https://jayleekr.github.io/Magnify/progress/project-kickoff.html)

## 🎯 성능 목표

| 지표 | 목표 | 현재 상태 |
|------|------|-----------|
| 줌 응답시간 | < 100ms | - |
| 메모리 사용량 | < 50MB | - |
| CPU 사용률 | < 30% (그리기 중) | - |
| 크래시율 | < 0.1% | - |
| 테스트 커버리지 | 80%+ | - |

## 🚀 로컬 개발 환경 설정

### 필수 요구사항
- macOS 12.3 이상
- Xcode 16 이상
- Swift 5.9 이상
- Apple Developer Program 계정 (App Store 배포용)

### 개발 환경 구성
```bash
# 저장소 클론
git clone https://github.com/jayleekr/Magnify.git
cd Magnify

# GitHub CLI 설치 (선택사항)
brew install gh

# 개발 진행상황 확인
gh workflow list
gh run list --limit 5
```

## 📱 App Store 출시 계획

### 수익화 전략
- **Phase 1:** 무료 배포 (사용자 확보)
- **Phase 2:** 인앱 구매 추가 ($2.99-$4.99)
- **Phase 3:** 유료 앱 전환 ($9.99-$14.99)

### 배포 정보
- **Bundle ID:** `com.jayleekr.magnify`
- **App Store Name:** Magnify - Screen Annotation Tool
- **Target:** macOS 12.3+
- **Category:** Productivity

## 🤝 기여하기

이 프로젝트는 현재 개인 프로젝트로 진행되고 있습니다. 개발 과정과 결과를 GitHub Pages에서 실시간으로 공유하고 있습니다.

### 피드백 및 제안
- 🐛 **버그 리포트:** [Issues](https://github.com/jayleekr/Magnify/issues)
- 💡 **기능 제안:** [Discussions](https://github.com/jayleekr/Magnify/discussions)
- 📧 **연락처:** [GitHub Profile](https://github.com/jayleekr)

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🔗 관련 링크

- 📱 **GitHub Repository:** https://github.com/jayleekr/Magnify
- 📖 **Development Blog:** https://jayleekr.github.io/Magnify/
- 🛠️ **Project Configuration:** [project_config.md](project_config.md)
- 🤖 **AI Development Prompts:** [ai_development_prompts.md](ai_development_prompts.md)

---

<div align="center">

**🚀 Magnify - macOS 화면 주석 도구 개발 프로젝트**

Built with ❤️ using Swift, AppKit, and modern macOS technologies

© 2025 Jay Lee

</div>
