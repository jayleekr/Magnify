# workflow_state.md
_Last updated: 2025-01-16_

## State
Phase: CONSTRUCT  
Status: RUNNING  
CurrentItem: Week 1-2 Core Infrastructure - Xcode 프로젝트 초기 설정  

## Plan
**Primary Goal:** macOS 네이티브 화면 주석 앱 개발 (ZoomIt 기능 구현)
**Target Timeline:** 9주 (개발 8주 + 배포 1주)
**Distribution:** Mac App Store (무료→유료 전환 전략)

### Development Roadmap:
1. **Week 1-2: Core Infrastructure**
   - Xcode 프로젝트 설정 (App Sandbox + Entitlements)
   - ScreenCaptureKit 화면 캡처 구현
   - 투명 오버레이 NSWindow 시스템 구축

2. **Week 3-4: Zoom & Annotation**
   - 실시간 화면 확대/축소 기능
   - NSBezierPath 기반 펜 그리기 시스템
   - RegisterEventHotKey 전역 단축키 구현

3. **Week 5-6: Advanced Features**
   - 텍스트 주석 시스템
   - 프레젠테이션 타이머 기능
   - SwiftUI 설정 UI

4. **Week 7-8: Polish & Testing**
   - 성능 최적화 (메모리 <50MB, 응답 <100ms)
   - TestFlight 베타 테스팅
   - App Store 메타데이터 준비

5. **Week 9: App Store Submission**
   - 코드 서명 및 아카이브
   - App Store Connect 업로드 및 심사

### Technical Implementation Strategy:
- **Primary Stack:** Swift + AppKit (NSWindow/NSView 제어)
- **Screen Capture:** ScreenCaptureKit (macOS 12.3+)
- **Drawing Engine:** NSBezierPath + Core Graphics
- **Global Hotkeys:** Carbon RegisterEventHotKey
- **UI Framework:** AppKit (메인) + SwiftUI (설정만)

### Monetization Phases:
- **Phase 1:** 무료 MVP (기본 기능)
- **Phase 2:** 인앱 구매 (고급 기능 $2.99-$4.99)
- **Phase 3:** 유료 전환 (신규 사용자 $9.99-$14.99)

## Rules
> **Keep every major section under an explicit H2 (`##`) heading so the agent can locate them unambiguously.**

### [PHASE: ANALYZE]
1. Read **project_config.md**, relevant code & docs.  
2. Summarize requirements. *No code or planning.*

### [PHASE: BLUEPRINT]
1. Decompose task into ordered steps.  
2. Write pseudocode or file-level diff outline under **## Plan**.  
3. Set `Status = NEEDS_PLAN_APPROVAL` and await user confirmation.

### [PHASE: CONSTRUCT]
1. Follow the approved **## Plan** exactly.  
2. After each atomic change:  
   - run test / linter commands specified in `project_config.md`  
   - capture tool output in **## Log**  
3. On success of all steps, set `Phase = VALIDATE`.

### [PHASE: VALIDATE]
1. Rerun full test suite & any E2E checks.  
2. If clean, set `Status = COMPLETED`.  
3. Trigger **RULE_ITERATE_01** when applicable.

---

### RULE_INIT_01
Trigger ▶ `Phase == INIT`  
Action ▶ Ask user for first high-level task → `Phase = ANALYZE, Status = RUNNING`.

### RULE_ITERATE_01
Trigger ▶ `Status == COMPLETED && Items contains unprocessed rows`  
Action ▶  
1. Set `CurrentItem` to next unprocessed row in **## Items**.  
2. Clear **## Log**, reset `Phase = ANALYZE, Status = READY`.

### RULE_LOG_ROTATE_01
Trigger ▶ `length(## Log) > 5 000 chars`  
Action ▶ Summarise the top 5 findings from **## Log** into **## ArchiveLog**, then clear **## Log**.

### RULE_SUMMARY_01
Trigger ▶ `Phase == VALIDATE && Status == COMPLETED`  
Action ▶ 
1. Read `project_config.md`.
2. Construct the new changelog line: `- <One-sentence summary of completed work>`.
3. Find the `## Changelog` heading in `project_config.md`.
4. Insert the new changelog line immediately after the `## Changelog` heading and its following newline (making it the new first item in the list).

---

## Items
| id | description | status |
|----|-------------|--------|
| 1 | Week 1-2: Xcode 프로젝트 초기 설정 및 권한 구성 | IN_PROGRESS |
| 2 | Week 1-2: ScreenCaptureKit 화면 캡처 기본 구현 | PENDING |
| 3 | Week 1-2: 투명 오버레이 NSWindow 시스템 구축 | PENDING |
| 4 | Week 3-4: 실시간 화면 확대/축소 기능 구현 | PENDING |
| 5 | Week 3-4: NSBezierPath 기반 펜 그리기 시스템 | PENDING |
| 6 | Week 3-4: RegisterEventHotKey 전역 단축키 구현 | PENDING |

## Log
**2025-01-16 - BLUEPRINT Phase Completed**
- PDF 가이드 "macOS용 ZoomIt 유사 앱 개발 가이드.pdf" 내용 분석 완료
- 구체적 기술 스택 확정: Swift + AppKit + ScreenCaptureKit 조합
- 상세 구현 방법론 도출:
  * 투명 NSWindow (borderless, .statusBar level, collectionBehavior)
  * ScreenCaptureKit 기반 화면 캡처 (화면 기록 권한 필요)
  * NSView 서브클래스에서 마우스 이벤트 처리로 실시간 그리기
  * RegisterEventHotKey로 전역 단축키 (샌드박스 환경 호환)
- App Store 배포 전략 수립:
  * App Sandbox + 코드 서명 + 화면 기록 권한
  * 무료 배포 후 인앱 구매 → 유료 전환 로드맵
- AI 개발 전략 포함: 프롬프트 엔지니어링 + GitHub Copilot 활용
- 9주 개발 타임라인 확정 (8주 개발 + 1주 배포)
- project_config.md 업데이트 완료 (PDF 가이드 기반 상세 기술 명세)

**Next Action:** EXECUTE 단계로 전환하여 Xcode 프로젝트 초기 설정 시작

## ArchiveLog
<!-- RULE_LOG_ROTATE_01 stores condensed summaries here -->
