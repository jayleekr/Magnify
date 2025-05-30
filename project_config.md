# project_config.md
Last-Updated: 2025-01-16

## Project Goal
**Magnify**: macOS에서 프레젠테이션 및 강의용 화면 주석 도구를 개발하여 ZoomIt과 동등한 기능을 제공하는 네이티브 앱을 만들고, 무료 배포 후 유료 전환 전략을 통해 Mac App Store에서 수익화합니다.

**Repository:** https://github.com/jayleekr/Magnify.git  
**Bundle ID:** com.jayleekr.magnify  
**App Store Name:** Magnify - Screen Annotation Tool  
**GitHub Pages:** https://jayleekr.github.io/Magnify/

## Tech Stack
- **Language(s):** Swift 5.9+ (주 언어), Objective-C++ (필요시 C++ 브리지용)
- **Framework(s):** 
  - AppKit (주 UI 프레임워크 - NSWindow, NSView 제어)
  - SwiftUI (설정/환경설정 UI만)
  - ScreenCaptureKit (macOS 12.3+ 화면 캡처)
  - CoreGraphics (화면 캡처 및 그래픽 처리)
  - Carbon (RegisterEventHotKey를 통한 전역 단축키)
- **Graphics & Performance:** 
  - Metal (GPU 가속 스케일링)
  - Core Animation (부드러운 애니메이션)
  - NSBezierPath (실시간 펜 그리기)
- **Build / Tooling:** 
  - Xcode 16+
  - Swift Package Manager
  - Apple Developer Program (앱스토어 배포용)
  - **GitHub CLI (gh)** - GitHub Actions 워크플로우 관리 및 배포 자동화
- **Distribution:** Mac App Store (코드 서명 + 샌드박스 필수)
- **Version Control:** Git + GitHub Actions for CI/CD
- **Documentation:** GitHub Pages (Jekyll 기반 개발 블로그)
- **DevOps & Automation:**
  - **GitHub Actions** - 자동 빌드, 테스트, GitHub Pages 배포
  - **GitHub CLI (gh)** - PR 생성, 워크플로우 상태 확인, 릴리즈 관리

## GitHub Workflow Strategy
### Repository Structure:
```
/Magnify
├── /Sources          # Swift 소스 코드
├── /Resources         # 리소스 파일 (아이콘, 설정)
├── /Tests            # 단위 테스트
├── /docs             # GitHub Pages 웹사이트
│   ├── index.html    # 메인 페이지
│   ├── /blog         # 마일스톤별 블로그 포스트
│   │   ├── milestone-1.html
│   │   ├── milestone-2.html
│   │   └── milestone-N.html
│   ├── /assets       # CSS, JS, 이미지
│   └── /screenshots  # 앱 데모 스크린샷/비디오
├── /Screenshots      # App Store용 스크린샷
├── .github/
│   └── workflows/    # GitHub Actions
└── README.md
```

### Milestone-Based Development & Documentation:
각 **체크포인트 완료 시 필수 작업** 수행:
1. **Feature Branch → Commit → Push**
2. **📝 Progress Documentation 업데이트** (README.md, 진행상황)
3. **🚨 GitHub Pages 문서 업데이트 및 배포**
4. **🔄 GitHub Actions 배포 상태 확인** (`gh workflow list`, `gh run list`)
5. **체크포인트별 PR 생성** (major checkpoint 완료 시)

### GitHub Pages Blog Requirements:
**📍 배포 주소:** https://jayleekr.github.io/Magnify/  
**📁 소스 위치:** `/docs` 폴더 (main 브랜치)  
**🎯 업데이트 트리거:** 각 **체크포인트 완료 시** (세부 작업 단위)  
**🤖 자동 배포:** GitHub Actions workflow 통한 자동 빌드 및 배포

**필수 문서 콘텐츠:**
- **메인 페이지** (`/docs/index.html`): 프로젝트 소개, **실시간 진행상황**, 기술 스택
- **개발 로그** (`/docs/progress/`): **각 체크포인트별 상세 진행 기록**
- **마일스톤 요약** (`/docs/milestones/milestone-N.html`): 주요 마일스톤 완료 시 종합 리포트
- **스크린샷/데모** (`/docs/screenshots/`): 각 체크포인트의 기능 시연 자료

**체크포인트별 문서 업데이트 구조:**
```
/docs/
├── index.html              # 메인 대시보드 (실시간 진행상황)
├── /progress/              # 세부 진행 기록
│   ├── checkpoint-1-1.html # "Xcode 프로젝트 설정 완료"
│   ├── checkpoint-1-2.html # "ScreenCaptureKit 기본 구현"
│   ├── checkpoint-1-3.html # "투명 오버레이 NSWindow"
│   └── checkpoint-N-M.html
├── /milestones/            # 주요 마일스톤 종합 리포트
│   ├── milestone-1.html    # Core Infrastructure 완료 시
│   └── milestone-N.html
└── /screenshots/           # 각 체크포인트별 스크린샷
```

### GitHub CLI 체크포인트 완료 워크플로우
```bash
# 체크포인트 완료 후 실행 명령어
git add . && git commit -m "✅ Checkpoint N.M: [제목] 완료"
git push origin feature/milestone-N-name

# 문서 업데이트 후 배포 확인
gh run list --workflow=pages-build
gh browse  # 업데이트된 사이트 확인

# Major checkpoint 완료 시 PR 생성
gh pr create --title "🎉 Milestone N 완료" --body "체크포인트 N.1~N.4 모두 완료"
```

## Development Milestones & Checkpoint Strategy

### 🎯 Milestone 1: Core Infrastructure (Week 1-2)
**Branch:** `feature/milestone-1-core-infrastructure`

#### Checkpoint 1.1: Xcode 프로젝트 설정 (Day 1-2)
**Deliverables:**
- [ ] Xcode 프로젝트 생성 및 기본 설정
- [ ] App Sandbox entitlements 설정
- [ ] Bundle ID 설정 (com.jayleekr.magnify)
- [ ] 코드 서명 설정

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-1-1.html`
- **제목:** "Xcode 프로젝트 설정과 App Sandbox 구성"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 1.2: ScreenCaptureKit 기본 구현 (Day 3-4)
**Deliverables:**
- [ ] ScreenCaptureKit 권한 요청 구현
- [ ] 기본 화면 캡처 기능 구현
- [ ] 권한 거부 시 사용자 안내 UI
- [ ] 기본 에러 처리

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-1-2.html`
- **제목:** "ScreenCaptureKit 권한과 기본 화면 캡처"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 1.3: 투명 오버레이 NSWindow (Day 5-7)
**Deliverables:**
- [ ] 투명 NSWindow 생성 (borderless, statusBar level)
- [ ] 모든 Spaces에서 표시 설정
- [ ] 최상위 표시 (orderFrontRegardless)
- [ ] 기본 마우스 이벤트 처리

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-1-3.html`
- **제목:** "투명 오버레이 NSWindow 시스템 구축"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 1.4: 단위 테스트 및 CI 설정 (Day 8-10)
**Deliverables:**
- [ ] XCTest 테스트 타겟 설정
- [ ] 기본 테스트 케이스 작성
- [ ] GitHub Actions Swift CI 워크플로우
- [ ] 테스트 커버리지 측정

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-1-4.html`
- **제목:** "단위 테스트와 GitHub Actions CI/CD 구축"
- **배포:** 체크포인트 완료 즉시

**🎉 Milestone 1 완료 시:**
- **Major PR 생성:** `feature/milestone-1-core-infrastructure` → `develop`
- **GitHub Release:** `v0.1.0`
- **종합 리포트:** `/docs/milestones/milestone-1.html`

### 🎯 Milestone 2: Zoom & Annotation Core (Week 3-4)
**Branch:** `feature/milestone-2-zoom-annotation`

#### Checkpoint 2.1: 실시간 화면 확대/축소 (Day 11-13)
**Deliverables:**
- [ ] 마우스 위치 기준 확대/축소 로직
- [ ] Metal/CoreGraphics 성능 비교 및 선택
- [ ] 부드러운 스케일링 애니메이션
- [ ] 확대 배율 제한 설정

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-2-1.html`
- **제목:** "실시간 화면 확대/축소 엔진 구현"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 2.2: NSBezierPath 그리기 시스템 (Day 14-16)
**Deliverables:**
- [ ] mouseDown/mouseDragged/mouseUp 이벤트 처리
- [ ] 실시간 드래그 궤적 저장
- [ ] NSBezierPath 렌더링 최적화
- [ ] 메모리 효율적인 Path 관리

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-2-2.html`
- **제목:** "NSBezierPath 실시간 펜 그리기 시스템"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 2.3: 전역 단축키 구현 (Day 17-19)
**Deliverables:**
- [ ] Carbon RegisterEventHotKey 구현
- [ ] 샌드박스 환경에서 동작 확인
- [ ] 기본 단축키 설정 (확대/축소, 그리기 모드)
- [ ] 시스템 단축키 충돌 방지

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-2-3.html`
- **제목:** "Carbon RegisterEventHotKey와 전역 단축키"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 2.4: 기본 UI/UX 완성 (Day 20-22)
**Deliverables:**
- [ ] 상태 표시 UI (확대 모드, 그리기 모드)
- [ ] 기본 툴바 또는 컨텍스트 메뉴
- [ ] 키보드 단축키 안내
- [ ] 기본 사용자 인터랙션 폴리싱

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-2-4.html`
- **제목:** "사용자 인터페이스와 인터랙션 디자인"
- **배포:** 체크포인트 완료 즉시

**🎉 Milestone 2 완료 시:**
- **Major PR 생성:** `feature/milestone-2-zoom-annotation` → `develop`
- **GitHub Release:** `v0.2.0`
- **종합 리포트:** `/docs/milestones/milestone-2.html`

### 🎯 Milestone 3: Advanced Features (Week 5-6)
**Branch:** `feature/milestone-3-advanced`

#### Checkpoint 3.1: 텍스트 주석 시스템 (Day 23-25)
**Deliverables:**
- [ ] NSTextField를 활용한 인라인 텍스트 입력
- [ ] 텍스트 박스 위치 조정 및 크기 변경
- [ ] 폰트 크기, 색상 선택 기능
- [ ] 텍스트 주석 저장 및 편집

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-3-1.html`
- **제목:** "NSTextField 텍스트 주석 시스템 구현"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 3.2: 프레젠테이션 타이머 (Day 26-28)
**Deliverables:**
- [ ] 카운트다운/카운트업 타이머 구현
- [ ] 타이머 오버레이 UI 디자인
- [ ] 시간 설정 및 알람 기능
- [ ] 타이머 일시정지/재시작 기능

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-3-2.html`
- **제목:** "프레젠테이션 타이머와 알람 시스템"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 3.3: SwiftUI 설정 UI (Day 29-31)
**Deliverables:**
- [ ] SwiftUI 설정 창 구현
- [ ] 단축키 커스터마이징 인터페이스
- [ ] 펜 도구 기본값 설정
- [ ] AppKit ↔ SwiftUI 데이터 바인딩

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-3-3.html`
- **제목:** "SwiftUI와 AppKit 하이브리드 설정 UI"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 3.4: 다양한 펜 도구 (Day 32-34)
**Deliverables:**
- [ ] 색상 팔레트 UI 구현
- [ ] 펜 굵기 조절 슬라이더
- [ ] 하이라이터, 지우개 도구 추가
- [ ] 도구별 NSBezierPath 스타일 적용

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-3-4.html`
- **제목:** "다양한 펜 도구와 색상 시스템"
- **배포:** 체크포인트 완료 즉시

**🎉 Milestone 3 완료 시:**
- **Major PR 생성:** `feature/milestone-3-advanced` → `develop`
- **GitHub Release:** `v0.3.0`
- **종합 리포트:** `/docs/milestones/milestone-3.html`

### 🎯 Milestone 4: Polish & Testing (Week 7-8)
**Branch:** `feature/milestone-4-polish`

#### Checkpoint 4.1: 성능 최적화 (Day 35-37)
**Deliverables:**
- [ ] 메모리 사용량 <50MB 달성
- [ ] 줌 응답시간 <100ms 최적화
- [ ] CPU 사용률 <30% 튜닝
- [ ] Instruments를 통한 성능 프로파일링

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-4-1.html`
- **제목:** "Instruments 성능 프로파일링과 최적화"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 4.2: 포괄적 테스팅 (Day 38-40)
**Deliverables:**
- [ ] 단위 테스트 커버리지 80%+ 달성
- [ ] UI 테스트 자동화 (XCUITest)
- [ ] 에지 케이스 테스트 시나리오
- [ ] 메모리 누수 테스트

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-4-2.html`
- **제목:** "XCTest와 XCUITest 포괄적 테스팅"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 4.3: TestFlight 베타 (Day 41-43)
**Deliverables:**
- [ ] TestFlight 베타 빌드 생성
- [ ] 내부 테스터 그룹 구성
- [ ] 베타 피드백 수집 시스템
- [ ] 크래시 리포트 모니터링

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-4-3.html`
- **제목:** "TestFlight 베타 테스팅과 피드백 수집"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 4.4: App Store 메타데이터 (Day 44-46)
**Deliverables:**
- [ ] App Store 스크린샷 제작
- [ ] 앱 설명 및 키워드 최적화
- [ ] 프라이버시 정책 작성
- [ ] 마케팅 자료 완성

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-4-4.html`
- **제목:** "App Store 메타데이터와 마케팅 자료"
- **배포:** 체크포인트 완료 즉시

**🎉 Milestone 4 완료 시:**
- **Major PR 생성:** `feature/milestone-4-polish` → `develop`
- **GitHub Release:** `v0.9.0`
- **종합 리포트:** `/docs/milestones/milestone-4.html`

### 🎯 Milestone 5: App Store Launch (Week 9)
**Branch:** `release/v1.0.0`

#### Checkpoint 5.1: 코드 서명 및 아카이브 (Day 47-48)
**Deliverables:**
- [ ] Apple Distribution 인증서 설정
- [ ] 프로덕션 프로비저닝 프로파일
- [ ] Xcode Archive 빌드 생성
- [ ] 코드 서명 검증

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-5-1.html`
- **제목:** "Apple Distribution 코드 서명과 아카이브"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 5.2: App Store Connect 업로드 (Day 49-50)
**Deliverables:**
- [ ] App Store Connect 앱 등록
- [ ] 빌드 업로드 및 검증
- [ ] 메타데이터 최종 검토
- [ ] 심사 제출 준비

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-5-2.html`
- **제목:** "App Store Connect 업로드와 심사 제출"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 5.3: 심사 대응 (Day 51-53)
**Deliverables:**
- [ ] Apple 심사팀 피드백 대응
- [ ] 리젝트 시 수정사항 반영
- [ ] 재제출 프로세스 관리
- [ ] 승인 대기 및 모니터링

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-5-3.html`
- **제목:** "Apple 앱 심사 과정과 대응 전략"
- **배포:** 체크포인트 완료 즉시

#### Checkpoint 5.4: 마케팅 자료 완성 (Day 54-56)
**Deliverables:**
- [ ] 공식 웹사이트 런칭
- [ ] 소셜 미디어 계정 생성
- [ ] 프레스 릴리즈 작성
- [ ] 런칭 이벤트 계획

**📝 문서 업데이트:**
- **파일:** `/docs/progress/checkpoint-5-4.html`
- **제목:** "Magnify 출시 마케팅과 홍보 전략"
- **배포:** 체크포인트 완료 즉시

**🎉 Milestone 5 완료 시:**
- **Major PR 생성:** `release/v1.0.0` → `main`
- **GitHub Release:** `v1.0.0` (공식 출시)
- **종합 리포트:** `/docs/milestones/milestone-5.html`
- **🚀 App Store 출시 완료!**

## 체크포인트별 GitHub Pages 업데이트 전략

### GitHub Actions Workflow Strategy:
**워크플로우 파일 위치:** `.github/workflows/`

**필수 워크플로우:**
1. **`pages-deploy.yml`** - GitHub Pages 자동 배포 (체크포인트마다 트리거)
2. **`swift-ci.yml`** - Swift 코드 빌드 및 테스트 (모든 커밋)
3. **`checkpoint-report.yml`** - 체크포인트 완료 시 자동 문서 생성

**GitHub Pages 자동 배포 설정:**
```yaml
# .github/workflows/pages-deploy.yml
name: Deploy GitHub Pages
on:
  push:
    branches: [ main ]
    paths: [ 'docs/**' ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pages: write
      id-token: write
    
    steps:
    - uses: actions/checkout@v4
    - name: Setup Pages
      uses: actions/configure-pages@v4
    - name: Upload artifact
      uses: actions/upload-pages-artifact@v3
      with:
        path: './docs'
    - name: Deploy to GitHub Pages
      uses: actions/deploy-pages@v4
```

**배포 상태 모니터링:**
- **실시간 확인:** `gh run watch` (워크플로우 실행 중 실시간 로그)
- **배포 완료 확인:** `gh run list --limit 5` (최근 5개 실행 결과)
- **실패 시 디버깅:** `gh run view --log` (실패한 워크플로우 로그 확인)

### Branch Strategy:
- **main:** 안정적인 릴리즈 브랜치 + GitHub Pages 소스
- **develop:** 개발 통합 브랜치  
- **feature/milestone-1-core-infrastructure:** 각 마일스톤별 기능 브랜치
- **hotfix/*:** 긴급 수정사항

## Critical Patterns & Conventions
- **Architecture:** MVC 패턴 (AppKit 기반) + MVVM (SwiftUI 설정)
- **Window Management:** 
  - 투명 NSWindow (borderless, .statusBar level)
  - collectionBehavior = [.canJoinAllSpaces] (모든 Spaces에서 표시)
  - orderFrontRegardless() (최상위 표시)
- **Screen Capture Strategy:**
  - Primary: ScreenCaptureKit (macOS 12.3+)
  - Fallback: CGWindowListCreateImage (레거시 지원)
  - 화면 기록 권한 필수 (com.apple.security.screen-capture)
- **Drawing Implementation:**
  - NSView 서브클래스에서 mouseDown/mouseDragged/mouseUp 오버라이드
  - 실시간 드래그 궤적을 배열에 저장 후 NSBezierPath로 렌더링
  - GPU 가속을 위해 CALayer 또는 Metal 텍스처 활용
- **Global Hotkeys:** RegisterEventHotKey (샌드박스 환경에서도 동작)
- **Performance Requirements:**
  - 줌 응답시간: <100ms
  - 메모리 사용량: <50MB
  - CPU 사용률: 실시간 그리기 중 <30%

## Constraints
- **App Store Compliance:**
  - App Sandbox 필수 활성화
  - 화면 기록 권한 (Screen Recording) 사용자 승인 필요
  - 코드 서명: Apple Distribution 인증서
  - Entitlements: com.apple.security.screen-capture
- **Compatibility:** macOS 12.3+ (ScreenCaptureKit 요구사항)
- **Security:**
  - 샌드박스 내에서 전역 단축키 처리
  - 사용자 프라이버시 권한 안내 UI 필수
  - 번들 ID 고정: com.jayleekr.magnify
- **Distribution Strategy:**
  - Phase 1: 무료 배포 (사용자 확보)
  - Phase 2: 인앱 구매 추가 (프리미엄 기능)
  - Phase 3: 앱 자체 유료 전환 (신규 사용자만)

## Success Metrics

### 🎯 체크포인트별 성과 지표
- **일일 진행률:** 각 체크포인트 2-3일 내 완료
- **문서화 품질:** 각 체크포인트마다 기술 문서 완성도 95%+
- **GitHub Pages 업데이트:** 체크포인트 완료 후 24시간 내 배포
- **코드 품질:** 각 체크포인트마다 빌드 성공률 100%

### 📈 마일스톤별 성과 지표
- **Milestone 1 (Week 1-2):** 기본 인프라 구축, 테스트 커버리지 60%+
- **Milestone 2 (Week 3-4):** 핵심 기능 구현, 성능 벤치마크 달성
- **Milestone 3 (Week 5-6):** 고급 기능 완성, UI/UX 폴리싱
- **Milestone 4 (Week 7-8):** 품질 보증, TestFlight 준비 완료
- **Milestone 5 (Week 9):** App Store 출시 성공

### 🏆 최종 성공 지표
- **기술적:** 줌 응답 <100ms, 메모리 <50MB, 크래시율 <0.1%
- **사용자:** App Store 평점 4.5+, 리뷰 100+
- **수익:** Phase 2에서 월 $1,000+, Phase 3에서 월 $5,000+
- **성장:** 월 다운로드 1,000+, 활성 사용자 70%+
- **📊 개발 문서:** 총 20개 체크포인트 문서, 평균 500+ 조회수
- **🌟 GitHub Pages:** 월 방문자 1,000+, 기술 커뮤니티 노출

## Tokenization Settings
ESTIMATE_MIN_RESPONSE_TOKENS: 150
ESTIMATE_MAX_RESPONSE_TOKENS: 800
ESTIMATE_TOKEN_LIMIT: 120000
USE_32K_CONTEXT_MODELS: false
