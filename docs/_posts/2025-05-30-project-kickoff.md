---
layout: post
title: "🚀 Magnify 프로젝트 시작 - ZoomIt 대안 macOS 앱 개발 여정의 첫걸음"
date: 2025-05-30 09:00:00 +0900
category: "프로젝트 기획"
description: "Windows ZoomIt과 동등한 기능을 제공하는 macOS 네이티브 화면 주석 도구를 Swift로 개발하여 Mac App Store에 출시하고 수익화하는 프로젝트의 시작"
tags: [프로젝트시작, macOS, Swift, ZoomIt, 앱개발]
milestone: 1
checkpoint: 1
author: "Jay Lee"
---

## 🔍 프로젝트 탄생 배경

macOS에서 프레젠테이션이나 강의를 할 때 화면을 확대하거나 주석을 그려야 하는 경우가 종종 있습니다. Windows에서는 Microsoft의 **ZoomIt**이라는 훌륭한 도구가 있지만, macOS에는 이와 동등한 수준의 네이티브 앱이 부족한 상황입니다.

이 프로젝트는 다음과 같은 필요에서 시작되었습니다:

- **프레젠테이션 효율성:** 화면의 특정 부분을 확대해서 보여주고 싶을 때
- **실시간 주석:** 화면에 직접 그림을 그려서 설명하고 싶을 때
- **시간 관리:** 프레젠테이션 시간을 체크하고 싶을 때
- **macOS 네이티브 경험:** macOS의 성능과 사용성을 최대한 활용하고 싶을 때

## 📋 프로젝트 준비 과정

실제 개발에 들어가기 전에 충분한 계획과 준비가 필요했습니다. 지난 며칠간 다음과 같은 준비 작업을 진행했습니다:

### 1. ZoomIt 기능 분석
Windows ZoomIt의 모든 기능을 분석하고 macOS 환경에서 구현 가능한 기능들을 정리했습니다.

### 2. macOS 개발 가이드 연구
macOS 앱 개발을 위한 기술 스택, 제약사항, App Store 배포 전략을 상세히 조사했습니다.

### 3. 기술 스택 선정
Swift + AppKit + ScreenCaptureKit 조합으로 최적의 성능과 사용자 경험을 제공하기로 결정했습니다.

### 4. 프로젝트 구조 설계
5개 마일스톤, 20개 체크포인트로 구성된 상세한 개발 계획을 수립했습니다.

### 5. GitHub 저장소 및 Pages 설정
버전 관리와 개발 과정 문서화를 위한 인프라를 구축했습니다.

## 🛠️ 기술 스택 선정

macOS 네이티브 앱으로서 최고의 성능과 사용자 경험을 제공하기 위해 다음과 같은 기술 스택을 선정했습니다:

| 기술 | 용도 | 선정 이유 |
|------|------|-----------|
| **Swift 5.9+** | 주 개발 언어 | 최신 Swift 기능을 활용하여 안전하고 효율적인 코드 작성 |
| **AppKit** | UI 프레임워크 | macOS 네이티브 UI, 투명 오버레이와 복잡한 윈도우 관리 |
| **ScreenCaptureKit** | 화면 캡처 | macOS 12.3+의 최신 화면 캡처 API, 높은 성능과 보안 |
| **Metal** | GPU 가속 | 실시간 화면 확대/축소 처리로 부드러운 사용자 경험 |
| **Carbon** | 전역 단축키 | RegisterEventHotKey를 통한 App Sandbox 환경 지원 |
| **SwiftUI** | 설정 UI | 현대적이고 직관적인 설정 인터페이스 |

## 📅 개발 계획

총 9주(56일)에 걸쳐 5개의 주요 마일스톤으로 나누어 개발을 진행할 예정입니다:

### Milestone 1: Core Infrastructure (Week 1-2)
- ✅ Checkpoint 1.1: Xcode 프로젝트 설정 및 App Sandbox 구성
- ⏳ Checkpoint 1.2: ScreenCaptureKit 권한 및 기본 화면 캡처
- ⏳ Checkpoint 1.3: 투명 오버레이 NSWindow 시스템
- ⏳ Checkpoint 1.4: 단위 테스트 및 GitHub Actions CI/CD

### Milestone 2: Zoom & Annotation Core (Week 3-4)
- ⏳ Checkpoint 2.1: 실시간 화면 확대/축소 엔진
- ⏳ Checkpoint 2.2: NSBezierPath 기반 펜 그리기 시스템
- ⏳ Checkpoint 2.3: Carbon RegisterEventHotKey 전역 단축키
- ⏳ Checkpoint 2.4: 기본 사용자 인터페이스

### Milestone 3: Advanced Features (Week 5-6)
- ⏳ Checkpoint 3.1: NSTextField 텍스트 주석 시스템
- ⏳ Checkpoint 3.2: 프레젠테이션 타이머 및 알람
- ⏳ Checkpoint 3.3: SwiftUI 하이브리드 설정 UI
- ⏳ Checkpoint 3.4: 다양한 펜 도구와 색상 시스템

### Milestone 4: Polish & Testing (Week 7-8)
- ⏳ Checkpoint 4.1: 성능 최적화 (메모리 <50MB, 응답 <100ms)
- ⏳ Checkpoint 4.2: 포괄적 테스팅 (XCTest, XCUITest)
- ⏳ Checkpoint 4.3: TestFlight 베타 테스팅
- ⏳ Checkpoint 4.4: App Store 메타데이터 및 마케팅 자료

### Milestone 5: App Store Launch (Week 9)
- ⏳ Checkpoint 5.1: Apple Distribution 코드 서명
- ⏳ Checkpoint 5.2: App Store Connect 업로드
- ⏳ Checkpoint 5.3: Apple 심사 대응
- ⏳ Checkpoint 5.4: 공식 출시 및 마케팅

## 🎯 핵심 기능 설계

Magnify는 다음과 같은 핵심 기능들을 제공할 예정입니다:

> **🔍 실시간 화면 확대/축소:** 마우스 위치를 중심으로 부드러운 확대/축소를 제공하며, Metal GPU 가속을 통해 100ms 이하의 응답 시간을 목표로 합니다.

> **✏️ 실시간 주석 그리기:** NSBezierPath를 활용한 부드러운 펜 그리기와 다양한 색상, 굵기 옵션을 제공합니다.

> **📝 텍스트 주석:** 화면 위 임의의 위치에 텍스트를 추가하고 편집할 수 있는 기능을 제공합니다.

> **⏱️ 프레젠테이션 타이머:** 카운트다운/카운트업 타이머와 시각적 알람으로 시간 관리를 돕습니다.

> **⌨️ 전역 단축키:** App Sandbox 환경에서도 동작하는 전역 단축키로 어떤 앱에서든 빠르게 기능을 활성화할 수 있습니다.

## 📊 성능 목표

사용자 경험을 위해 다음과 같은 성능 목표를 설정했습니다:

```
줌 응답시간: <100ms
메모리 사용량: <50MB
CPU 사용률: 실시간 그리기 중 <30%
크래시율: <0.1%
테스트 커버리지: 80%+
```

## 🚀 개발 방법론

이 프로젝트는 다음과 같은 개발 방법론을 적용합니다:

### 체크포인트 기반 개발
각 마일스톤을 4개의 체크포인트로 나누어, 2-3일마다 구체적인 성과물을 완성하고 문서화합니다.

### 지속적 문서화
모든 체크포인트 완료 시마다 GitHub Pages에 개발 과정, 도전과제, 해결책을 상세히 기록합니다.

### AI 기반 개발 가속화
각 마일스톤별로 상세한 AI 개발 프롬프트를 준비하여 효율적인 개발을 진행합니다.

### GitHub 기반 협업
모든 코드는 GitHub에서 관리되며, Actions를 통한 자동 빌드/테스트/배포를 구현합니다.

## 💰 수익화 전략

앱의 지속 가능한 개발을 위해 단계적 수익화 전략을 수립했습니다:

- **Phase 1 (출시 직후):** 무료 배포로 사용자 확보 및 피드백 수집
- **Phase 2 (3개월 후):** 프리미엄 기능에 대한 인앱 구매 ($2.99-$4.99) 추가
- **Phase 3 (6개월 후):** 신규 사용자에게 유료 앱 ($9.99-$14.99) 전환

## 🔮 다음 단계

이제 모든 준비가 완료되었습니다! 다음 포스트에서는 첫 번째 체크포인트인 **"Xcode 프로젝트 설정과 App Sandbox 구성"** 과정을 상세히 다룰 예정입니다.

앞으로 9주간의 개발 여정이 기대됩니다. ZoomIt을 뛰어넘는 macOS 최고의 화면 주석 도구를 만들어보겠습니다! 🚀

---

**📍 현재 진행상황:** 프로젝트 기획 완료, GitHub Pages 설정 완료  
**⏭️ 다음 체크포인트:** Checkpoint 1.1 - Xcode 프로젝트 설정 (Day 1-2) 