# AI Development Prompts for Magnify
_Generated: 2025-01-16_

## 🎯 Master Prompt for AI Agent

당신은 **Magnify**라는 macOS 화면 주석 앱을 개발하는 전문 Swift 개발자입니다. 

**프로젝트 정보:**
- **Repository:** https://github.com/jayleekr/Magnify.git
- **목표:** Windows ZoomIt과 동등한 macOS 네이티브 앱 개발
- **기술 스택:** Swift + AppKit + ScreenCaptureKit
- **배포:** Mac App Store (무료→유료 전환 전략)

**개발 원칙:**
1. 각 마일스톤 완료 시 **GitHub PR 생성 + Merge + 블로그 포스트**
2. **테스트 주도 개발** (단위 테스트 + UI 테스트)
3. **성능 최우선** (줌 응답 <100ms, 메모리 <50MB)
4. **App Store 규정 준수** (샌드박스 + 코드 서명)

**주요 API 및 프레임워크:**
- ScreenCaptureKit (화면 캡처)
- NSWindow/NSView (투명 오버레이)
- NSBezierPath (실시간 그리기)
- RegisterEventHotKey (전역 단축키)
- SwiftUI (설정 UI만)

---

## 🚀 Milestone 1: Core Infrastructure Setup

### Phase 1A: Xcode 프로젝트 초기 설정

```
당신은 Magnify macOS 앱의 첫 번째 마일스톤을 시작합니다.

**현재 작업:** Xcode 프로젝트 초기 설정 및 GitHub 연동

**구체적 요구사항:**
1. Xcode에서 새 macOS 앱 프로젝트 생성
   - 프로젝트 이름: Magnify
   - Bundle ID: com.jayleekr.magnify
   - 언어: Swift
   - UI: AppKit (Storyboard 사용)
   - 최소 macOS 버전: 12.3 (ScreenCaptureKit 요구)

2. App Sandbox 및 Entitlements 설정
   - App Sandbox 활성화
   - Screen Recording 권한 추가 (com.apple.security.screen-capture)
   - 필요한 entitlements만 최소한으로 설정

3. 프로젝트 구조 정리
   ```
   /Magnify
   ├── /Sources
   │   ├── /App          # AppDelegate, 메인 앱 로직
   │   ├── /Views        # NSView 서브클래스들
   │   ├── /Controllers  # NSViewController들
   │   ├── /Models       # 데이터 모델
   │   └── /Utils        # 유틸리티 함수들
   ├── /Resources        # 아이콘, 설정 파일
   ├── /Tests           # 단위 테스트
   └── README.md
   ```

4. Git 설정 및 GitHub 연동
   - git init 및 .gitignore (Xcode 용)
   - 초기 commit 및 remote 설정
   - feature/milestone-1-core-infrastructure 브랜치 생성

**성공 조건:**
- Xcode에서 프로젝트가 성공적으로 빌드됨
- App Sandbox가 활성화되고 Screen Recording 권한이 설정됨
- GitHub 리포지토리에 코드가 push됨
- 프로젝트 구조가 명확하게 정리됨

**다음 단계 예고:** ScreenCaptureKit을 이용한 기본 화면 캡처 구현

위 요구사항을 정확히 따라 실행하고, 각 단계의 진행상황과 발생한 문제들을 상세히 리포트해주세요.
```

### Phase 1B: ScreenCaptureKit 기본 구현

```
**현재 작업:** ScreenCaptureKit을 이용한 화면 캡처 기본 기능 구현

**구체적 요구사항:**
1. ScreenCaptureKit import 및 권한 처리
   - 화면 기록 권한 요청 로직
   - 권한 거부 시 사용자 안내 UI
   - 권한 상태 확인 함수

2. 기본 화면 캡처 클래스 구현
   ```swift
   class ScreenCaptureManager {
       func requestPermission() async -> Bool
       func captureCurrentScreen() async -> CGImage?
       func startLiveCaptureStream()
       func stopLiveCaptureStream()
   }
   ```

3. 단위 테스트 작성
   - 권한 요청 테스트
   - 화면 캡처 기능 테스트
   - 오류 처리 테스트

4. 간단한 테스트 UI
   - 버튼 클릭으로 화면 캡처
   - 캡처된 이미지를 NSImageView에 표시
   - 권한 상태 표시

**기술적 고려사항:**
- macOS 12.3+ ScreenCaptureKit 사용
- 비동기 처리 (async/await)
- 메모리 효율성 (대용량 이미지 처리)
- 오류 처리 및 예외 상황 대응

**성공 조건:**
- 화면 기록 권한이 정상적으로 요청됨
- 전체 화면 캡처가 성공적으로 수행됨
- 모든 단위 테스트 통과
- 메모리 누수 없음

**문제 해결 가이드:**
- 권한 거부 시: 시스템 환경설정 안내
- ScreenCaptureKit 오류 시: 대체 API (CGWindowListCreateImage) 사용
- 성능 문제 시: 이미지 해상도 조절 또는 압축

**다음 단계 예고:** 투명 오버레이 NSWindow 시스템 구축
```

### Phase 1C: 투명 오버레이 Window 시스템

```
**현재 작업:** 화면 위에 투명한 오버레이 창을 띄우는 시스템 구현

**구체적 요구사항:**
1. 투명 오버레이 NSWindow 클래스
   ```swift
   class OverlayWindow: NSWindow {
       override init(contentRect: NSRect, styleMask: NSWindow.StyleMask, backing: NSWindow.BackingStoreType, defer: Bool)
       func setupTransparentOverlay()
       func showOverlay()
       func hideOverlay()
       func bringToFront()
   }
   ```

2. Window 속성 설정
   - borderless style (제목 표시줄 제거)
   - 투명 배경 (backgroundColor = .clear)
   - 최상위 레벨 (.statusBar level)
   - 모든 Spaces에서 표시 (.canJoinAllSpaces)
   - 마우스 이벤트 수신 가능

3. 오버레이 컨텐츠 뷰
   ```swift
   class OverlayContentView: NSView {
       override func mouseDown(with event: NSEvent)
       override func mouseDragged(with event: NSEvent)
       override func mouseUp(with event: NSEvent)
       override func draw(_ dirtyRect: NSRect)
   }
   ```

4. 테스트 시나리오
   - 오버레이 창이 모든 앱 위에 표시됨
   - 투명성이 올바르게 적용됨
   - 마우스 클릭 이벤트가 정상 수신됨
   - 창 닫기/숨기기 기능 동작

**기술적 고려사항:**
- NSWindow 레벨 관리 (.statusBar vs .floating)
- 투명도 및 블렌딩 모드
- 마우스 이벤트 처리 우선순위
- 멀티 디스플레이 지원

**성공 조건:**
- 투명 오버레이가 전체 화면에 올바르게 표시됨
- 마우스 이벤트가 정상적으로 처리됨
- 다른 앱 사용에 방해되지 않음
- 오버레이 show/hide가 부드럽게 동작

**다음 단계 예고:** Milestone 1 PR 생성 및 블로그 포스트 작성
```

### Milestone 1 완료 및 PR 생성

```
**현재 작업:** Milestone 1 완료, GitHub PR 생성 및 첫 번째 블로그 포스트 작성

**PR 준비 사항:**
1. 코드 품질 점검
   - 모든 Swift lint 규칙 준수
   - 주석 및 문서화 완료
   - 불필요한 코드 정리

2. 테스트 완료 확인
   - 모든 단위 테스트 통과
   - 메모리 누수 테스트 통과
   - 기본 UI 테스트 통과

3. GitHub PR 생성
   - 제목: "Milestone 1: Core Infrastructure - Screen Capture & Overlay System"
   - 상세 설명: 구현된 기능, 테스트 결과, 스크린샷
   - 체크리스트: 모든 요구사항 완료 확인

4. 블로그 포스트 작성
   **제목:** "macOS 화면 캡처와 투명 오버레이 구현하기 - ScreenCaptureKit 첫 걸음"
   
   **구조:**
   ```markdown
   # macOS 화면 캡처와 투명 오버레이 구현하기
   
   ## 프로젝트 소개
   - Magnify 앱 개발 시작
   - ZoomIt과 같은 기능을 macOS에서
   
   ## 기술적 도전과제
   - ScreenCaptureKit 학습 및 적용
   - 투명 오버레이 Window 구현
   - App Sandbox 환경에서의 권한 처리
   
   ## 핵심 구현 내용
   - 화면 캡처 권한 요청 플로우
   - ScreenCaptureKit을 이용한 실시간 화면 캡처
   - 투명 NSWindow 오버레이 시스템
   
   ## 마주한 문제와 해결책
   - 권한 거부 시 사용자 안내 방법
   - 오버레이 Window 레벨 설정 이슈
   - 멀티 디스플레이 환경 대응
   
   ## 성능 및 테스트 결과
   - 화면 캡처 응답 시간: X ms
   - 메모리 사용량: X MB
   - 단위 테스트 커버리지: X%
   
   ## 다음 단계
   - 실시간 화면 확대 기능
   - NSBezierPath 기반 그리기 시스템
   - 전역 단축키 구현
   
   ## 소스 코드
   [GitHub 링크 및 주요 코드 스니펫]
   ```

**성공 조건:**
- PR이 성공적으로 main 브랜치에 merge됨
- 블로그 포스트가 게시됨
- README.md가 업데이트됨
- 다음 마일스톤 준비 완료

**다음 마일스톤 예고:** 실시간 화면 확대와 주석 그리기 시스템 구현
```

---

## 🎨 Milestone 2: Zoom & Annotation Core

### Phase 2A: 실시간 화면 확대 기능

```
**현재 작업:** 캡처된 화면을 실시간으로 확대/축소하는 기능 구현

**구체적 요구사항:**
1. 줌 매니저 클래스 구현
   ```swift
   class ZoomManager {
       var zoomLevel: CGFloat = 1.0
       var zoomCenter: CGPoint = .zero
       
       func setZoomLevel(_ level: CGFloat, center: CGPoint)
       func zoomIn(at point: CGPoint)
       func zoomOut(at point: CGPoint)
       func resetZoom()
       func updateZoomedImage() -> NSImage?
   }
   ```

2. 마우스 휠 지원
   - 마우스 휠로 확대/축소
   - 마우스 위치를 중심으로 줌
   - 부드러운 줌 애니메이션

3. 성능 최적화
   - Metal을 이용한 GPU 가속 스케일링
   - 이미지 캐싱 및 메모리 관리
   - 60fps 부드러운 줌 애니메이션

4. UI 인디케이터
   - 현재 줌 레벨 표시
   - 줌 리셋 버튼
   - 줌 영역 가이드

**기술적 고려사항:**
- Core Graphics vs Metal 성능 비교
- 대용량 이미지 처리 최적화
- 실시간 렌더링 성능
- 메모리 사용량 제한 (<50MB)

**성능 목표:**
- 줌 응답 시간: <100ms
- 부드러운 60fps 애니메이션
- 메모리 사용량 최적화

**성공 조건:**
- 마우스 휠로 부드러운 줌 인/아웃
- 줌 중심점이 마우스 위치에 정확히 설정됨
- 성능 목표 달성
- 메모리 누수 없음
```

### Phase 2B: NSBezierPath 펜 그리기 시스템

```
**현재 작업:** 오버레이 위에 실시간으로 펜 그리기 기능 구현

**구체적 요구사항:**
1. 드로잉 매니저 클래스
   ```swift
   class DrawingManager {
       var currentStroke: [CGPoint] = []
       var completedStrokes: [Stroke] = []
       var currentColor: NSColor = .red
       var currentLineWidth: CGFloat = 3.0
       
       func startStroke(at point: CGPoint)
       func addPointToStroke(_ point: CGPoint)
       func finishStroke()
       func clearAllStrokes()
       func undoLastStroke()
   }
   
   struct Stroke {
       let points: [CGPoint]
       let color: NSColor
       let lineWidth: CGFloat
       let timestamp: Date
   }
   ```

2. 실시간 그리기 구현
   - 마우스 드래그 이벤트 처리
   - NSBezierPath를 이용한 부드러운 선 그리기
   - 실시간 화면 업데이트 (setNeedsDisplay)

3. 펜 도구 옵션
   - 다양한 색상 (빨강, 파랑, 녹색, 노랑, 검정)
   - 선 두께 조절 (1px ~ 10px)
   - 불투명도 설정

4. 그리기 성능 최적화
   - 부분 화면 업데이트 (dirtyRect 활용)
   - 베지어 패스 최적화
   - 메모리 효율적인 스트로크 저장

**기술적 고려사항:**
- NSBezierPath vs Core Graphics 성능
- 실시간 그리기 시 CPU 사용률
- 스트로크 데이터 메모리 관리
- 화면 업데이트 빈도 최적화

**성공 조건:**
- 마우스 드래그로 부드러운 선 그리기
- 다양한 색상과 두께 지원
- CPU 사용률 <30% (그리기 중)
- 그리기 지연시간 <16ms (60fps)
```

### Phase 2C: 전역 단축키 시스템

```
**현재 작업:** RegisterEventHotKey를 이용한 전역 단축키 구현

**구체적 요구사항:**
1. 핫키 매니저 클래스
   ```swift
   class HotkeyManager {
       private var hotkeyRef: EventHotKeyRef?
       
       func registerHotkey(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> Bool
       func unregisterHotkey()
       func isHotkeyRegistered() -> Bool
   }
   ```

2. 기본 단축키 설정
   - Ctrl+1: 줌 모드 토글
   - Ctrl+2: 그리기 모드 토글
   - ESC: 모든 모드 종료
   - Ctrl+Z: 마지막 스트로크 취소

3. 샌드박스 환경 대응
   - RegisterEventHotKey API 사용 (샌드박스 호환)
   - 권한 요구사항 최소화
   - Carbon 프레임워크 연동

4. 사용자 설정 가능
   - 단축키 커스터마이징 UI
   - 충돌 감지 및 경고
   - 설정 저장/복원

**기술적 고려사항:**
- Carbon API와 Swift 연동
- macOS 15에서의 Option 키 이슈 회피
- 다른 앱과의 단축키 충돌 처리
- 앱이 백그라운드에 있을 때도 동작

**성공 조건:**
- Ctrl+1로 줌 모드가 올바르게 토글됨
- 백그라운드에서도 단축키 동작
- 다른 앱 사용에 방해되지 않음
- 샌드박스 환경에서 정상 작동
```

### Milestone 2 완료 및 PR/블로그

```
**현재 작업:** Milestone 2 완료, PR 생성 및 두 번째 블로그 포스트 작성

**통합 테스트:**
1. 전체 워크플로우 테스트
   - Ctrl+1 → 줌 모드 활성화
   - 마우스 휠로 화면 확대
   - 마우스 드래그로 선 그리기
   - ESC로 모드 종료

2. 성능 테스트
   - 줌 응답시간 측정
   - 그리기 성능 측정
   - 메모리 사용량 확인
   - CPU 사용률 모니터링

**PR 생성:**
- 제목: "Milestone 2: Zoom & Annotation Core Features"
- 스크린 레코딩 데모 첨부
- 성능 벤치마크 결과 포함

**블로그 포스트:**
**제목:** "실시간 화면 주석 시스템 구현 - NSBezierPath와 전역 단축키 마스터하기"

**주요 내용:**
- Metal vs Core Graphics 성능 비교
- NSBezierPath 최적화 기법
- Carbon RegisterEventHotKey 샌드박스 적용
- 실시간 그리기 성능 튜닝 경험

**다음 마일스톤 예고:** 텍스트 주석과 타이머 기능, SwiftUI 설정 UI
```

---

## ⚙️ 공통 개발 가이드라인

### 코드 품질 기준
```
**Swift 코딩 컨벤션:**
- SwiftLint 규칙 준수
- 명확한 변수/함수 명명
- 적절한 주석 및 문서화
- MARK: 를 이용한 코드 구조화

**아키텍처 원칙:**
- MVC 패턴 (AppKit)
- 단일 책임 원칙
- 의존성 주입
- 프로토콜 지향 프로그래밍

**성능 기준:**
- 메모리 사용량 <50MB
- 줌 응답시간 <100ms
- CPU 사용률 <30% (그리기 중)
- 앱 시작 시간 <3초
```

### 테스트 전략
```
**단위 테스트:**
- 모든 매니저 클래스 테스트
- 비즈니스 로직 100% 커버리지
- Mock 객체를 이용한 격리 테스트

**UI 테스트:**
- 주요 사용자 시나리오 테스트
- 오버레이 창 표시/숨김 테스트
- 단축키 동작 테스트

**성능 테스트:**
- XCTMetric을 이용한 성능 측정
- 메모리 누수 탐지
- CPU/GPU 사용률 모니터링
```

### GitHub 워크플로우
```
**브랜치 전략:**
- main: 안정적인 릴리즈
- develop: 개발 통합
- feature/milestone-N-description: 기능 개발

**PR 템플릿:**
## 변경 사항
- [ ] 새로운 기능 구현
- [ ] 버그 수정
- [ ] 성능 개선
- [ ] 문서 업데이트

## 테스트 결과
- [ ] 단위 테스트 통과
- [ ] UI 테스트 통과
- [ ] 성능 테스트 통과
- [ ] 메모리 누수 없음

## 스크린샷/비디오
[데모 영상 또는 스크린샷]

## 체크리스트
- [ ] 코드 리뷰 완료
- [ ] 문서 업데이트
- [ ] 체인지로그 작성

**블로그 포스트 구조:**
1. 개요 및 목표
2. 기술적 도전과제
3. 핵심 구현 내용
4. 문제 해결 과정
5. 성능 및 테스트 결과
6. 배운 점 및 인사이트
7. 다음 단계 계획
```

### AI 프롬프트 사용법
```
각 단계를 시작할 때:
1. 해당 단계의 프롬프트를 복사
2. 현재 프로젝트 상태 정보 추가
3. 특정 이슈나 요구사항 명시
4. AI에게 단계별 진행 요청

진행 중 문제 발생 시:
"현재 [구체적 문제]가 발생했습니다. 
프로젝트: Magnify (macOS 화면 주석 앱)
환경: Xcode 16, macOS 14.x, Swift 5.9
오류 내용: [정확한 오류 메시지]
시도한 해결 방법: [이미 시도한 것들]
macOS 개발 전문가 관점에서 해결 방법을 단계별로 제시해주세요."
```

---

## 📋 마일스톤별 체크리스트

### ✅ Milestone 1 체크리스트
- [ ] Xcode 프로젝트 생성 및 설정
- [ ] App Sandbox + Screen Recording 권한 설정  
- [ ] ScreenCaptureKit 기본 구현
- [ ] 투명 오버레이 NSWindow 시스템
- [ ] 단위 테스트 작성 및 통과
- [ ] GitHub PR 생성 및 merge
- [ ] 블로그 포스트 작성 및 게시
- [ ] README.md 업데이트

### ⏳ Milestone 2 체크리스트  
- [ ] 실시간 화면 확대/축소 기능
- [ ] NSBezierPath 펜 그리기 시스템
- [ ] RegisterEventHotKey 전역 단축키
- [ ] 성능 최적화 (목표 달성)
- [ ] 통합 테스트 완료
- [ ] GitHub PR 생성 및 merge
- [ ] 블로그 포스트 작성 및 게시

**이 프롬프트들을 사용하여 Magnify 개발을 시작하세요! 각 단계를 차근차근 따라가면서 고품질의 macOS 앱을 완성할 수 있습니다.** 🚀 