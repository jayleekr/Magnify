# project_config.md

## Project Goal
**Magnify**: Develop a macOS native screen annotation tool that provides equivalent functionality to Windows ZoomIt, to be distributed on the Mac App Store with a free-to-paid monetization strategy.

**Repository:** https://github.com/jayleekr/Magnify.git  
**Bundle ID:** com.jayleekr.magnify  
**App Store Name:** Magnify - Screen Annotation Tool  
**GitHub Pages:** https://jayleekr.github.io/Magnify/

## Tech Stack
- **Language(s):** Swift 5.9+ (primary language), Objective-C++ (for C++ bridge if needed)
- **Framework(s):** 
  - AppKit (main UI framework - NSWindow, NSView control)
  - SwiftUI (settings/preferences UI only)
  - ScreenCaptureKit (macOS 12.3+ screen capture)
  - CoreGraphics (screen capture and graphics processing)
  - Carbon (global shortcuts via RegisterEventHotKey)
- **Graphics & Performance:** 
  - Metal (GPU accelerated scaling)
  - Core Animation (smooth animations)
  - NSBezierPath (real-time pen drawing)
- **Build / Tooling:** 
  - Xcode 16+
  - Swift Package Manager
  - Apple Developer Program (for App Store distribution)
  - **GitHub CLI (gh)** - GitHub Actions workflow management and deployment automation
- **Distribution:** Mac App Store (code signing + sandbox required)
- **Version Control:** Git + GitHub Actions for CI/CD
- **Documentation:** GitHub Pages (Jekyll-based development blog)
- **DevOps & Automation:**
  - **GitHub Actions** - automated build, test, GitHub Pages deployment
  - **GitHub CLI (gh)** - PR creation, workflow status check, release management

## Development Timeline 

### 🗓️ Project Schedule (May 30, 2025 Start)
**Project Start Date:** May 30, 2025  
**Total Development Period:** 9 weeks (63 days)

| Milestone | Duration | Start Date | End Date | Status |
|-----------|----------|------------|----------|---------|
| **Milestone 1: Core Infrastructure** | 2 weeks | 2025-05-30 | 2025-06-13 | 🚧 In Progress |
| **Milestone 2: Zoom & Annotation** | 2 weeks | 2025-06-14 | 2025-06-27 | ⏳ Pending |
| **Milestone 3: Advanced Features** | 2 weeks | 2025-06-28 | 2025-07-11 | ⏳ Pending |
| **Milestone 4: Polish & Testing** | 2 weeks | 2025-07-12 | 2025-07-25 | ⏳ Pending |
| **Milestone 5: App Store Launch** | 1 week | 2025-07-26 | 2025-08-01 | ⏳ Pending |

### 📅 Current Status
- **Current Date:** May 30, 2025
- **Active Milestone:** Milestone 1 (Core Infrastructure)  
- **Active Checkpoint:** 1.3 (Transparent Overlay Window System)
- **Progress:** 50% of Milestone 1 completed

### 🎯 Checkpoint Schedule (Milestone 1)
- **Checkpoint 1.1:** Xcode Project Setup ✅ (COMPLETED - May 30, 2025)
- **Checkpoint 1.2:** ScreenCaptureKit Implementation ✅ (COMPLETED - May 30, 2025)
- **Checkpoint 1.3:** Transparent Overlay Window System 🚧 (IN PROGRESS)
- **Checkpoint 1.4:** Global Hotkey Implementation ⏳ (Pending)

### 📝 Blog Post Timeline
All blog posts use the format: `YYYY-MM-DD-checkpoint-title.md`
- **2025-05-30:** Project Kickoff & Checkpoint 1.1 Completion
- **2025-05-30:** Checkpoint 1.2 Completion (ScreenCaptureKit Implementation)
- **2025-06-02:** Checkpoint 1.3 Completion (Estimated)
- **2025-06-05:** Checkpoint 1.4 Completion (Estimated)  
- **2025-06-08:** Milestone 1 Complete (Estimated)

### 🤖 GitHub CLI Automation Setup

**Automated PR Creation Workflow:**
```bash
# Method 1: SSH Key Authentication (Recommended - using existing SSH keys)
gh auth login --git-protocol ssh --web  # One-time setup
./.github/scripts/create-checkpoint-pr.sh 1.2 "ScreenCaptureKit Implementation"

# Method 2: Environment Variable (Alternative for CI/CD)
export GITHUB_TOKEN="your_github_token_here"
./.github/scripts/create-checkpoint-pr.sh 1.2 "ScreenCaptureKit Implementation"

# Method 3: One-time Token Authentication
echo "your_github_token_here" | gh auth login --with-token
./.github/scripts/create-checkpoint-pr.sh 1.2

# Method 4: Interactive Setup (Automated script)
./.github/scripts/setup-gh-auth.sh
```

**SSH Key Authentication Setup (Recommended):**
1. Ensure SSH key is working: `ssh -T git@github.com`
2. Run: `gh auth login --git-protocol ssh --web`
3. Choose your preferred SSH key (id_ed25519.pub recommended)
4. Complete web browser authentication
5. Test: `gh auth status`

**GitHub Personal Access Token Setup:**
1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with scopes: `repo`, `workflow`, `admin:public_key`
3. Save token securely and use in automation scripts

**Automation Scripts:**
- `.github/scripts/setup-gh-auth.sh` - Automated authentication setup
- `.github/scripts/create-checkpoint-pr.sh` - Automated PR creation
- Both scripts support multiple authentication methods

**Checkpoint Workflow Commands:**
```bash
# 1. Create feature branch
git checkout -b feature/checkpoint-X-Y-name

# 2. Implement changes and commit
git add . && git commit -m "✅ Checkpoint X.Y: Description"

# 3. Push and create PR (automated)
git push origin feature/checkpoint-X-Y-name
./.github/scripts/create-checkpoint-pr.sh X.Y "Title" "Description"
```

## GitHub Workflow Strategy
### Repository Structure:
```
/Magnify
├── /Sources          # Swift source code
├── /Resources         # Resource files (icons, settings)
├── /Tests            # Unit tests
├── /docs             # GitHub Pages website
│   ├── index.html    # Main page
│   ├── /blog         # Milestone blog posts
│   │   ├── milestone-1.html
│   │   ├── milestone-2.html
│   │   └── milestone-N.html
│   ├── /assets       # CSS, JS, images
│   └── /screenshots  # App demo screenshots/videos
├── /Screenshots      # App Store screenshots
├── .github/
│   └── workflows/    # GitHub Actions
└── README.md
```

### Milestone-Based Development & Documentation:
**Required tasks upon completion of each checkpoint:**
1. **Feature Branch → Commit → Push**
2. **📝 Progress Documentation Update** (README.md, progress status)
3. **🚨 GitHub Pages document update and deployment**
4. **🔄 GitHub Actions deployment status check** (`gh workflow list`, `gh run list`)
5. **Checkpoint PR creation** (upon major checkpoint completion)

### GitHub Pages Blog Requirements:
**📍 Deployment URL:** https://jayleekr.github.io/Magnify/  
**📁 Source Location:** `/docs` folder (main branch)  
**🎯 Update Trigger:** Upon **checkpoint completion** (detailed task units)  
**🤖 Auto Deployment:** Automated build and deployment via GitHub Actions workflow

**Required Document Content:**
- **Main Page** (`/docs/index.html`): Project introduction, **real-time progress**, tech stack
- **Development Log** (`/docs/progress/`): **Detailed progress record for each checkpoint**
- **Milestone Summary** (`/docs/milestones/milestone-N.html`): Comprehensive report upon major milestone completion
- **Screenshots/Demos** (`/docs/screenshots/`): Feature demonstration materials for each checkpoint

**Checkpoint Document Update Structure:**
```
/docs/
├── index.html              # Main dashboard (real-time progress)
├── /progress/              # Detailed progress records
│   ├── checkpoint-1-1.html # "Xcode Project Setup Complete"
│   ├── checkpoint-1-2.html # "ScreenCaptureKit Basic Implementation"
│   ├── checkpoint-1-3.html # "Transparent Overlay NSWindow"
│   └── checkpoint-N-M.html
├── /milestones/            # Major milestone comprehensive reports
│   ├── milestone-1.html    # Upon Core Infrastructure completion
│   └── milestone-N.html
└── /screenshots/           # Screenshots for each checkpoint
```

### GitHub CLI Checkpoint Completion Workflow
```bash
# Commands to execute after checkpoint completion
git add . && git commit -m "✅ Checkpoint N.M: [Title] Complete"
git push origin feature/milestone-N-name

# Check deployment after document update
gh run list --workflow=pages-build
gh browse  # Check updated site

# Create PR upon major checkpoint completion
gh pr create --title "🎉 Milestone N Complete" --body "All checkpoints N.1~N.4 completed"
```

## Development Milestones & Checkpoint Strategy

### 🎯 Milestone 1: Core Infrastructure
**Branch:** `feature/milestone-1-core-infrastructure`

#### Checkpoint 1.1: Xcode Project Setup
**Deliverables:**
- [ ] Xcode project creation and basic setup
- [ ] App Sandbox entitlements configuration
- [ ] Bundle ID setup (com.jayleekr.magnify)
- [ ] Code signing configuration

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-1-1.html`
- **Title:** "Xcode Project Setup and App Sandbox Configuration"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 1.2: ScreenCaptureKit Basic Implementation
**Deliverables:**
- [ ] ScreenCaptureKit permission request implementation
- [ ] Basic screen capture functionality implementation
- [ ] User guidance UI when permission denied
- [ ] Basic error handling

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-1-2.html`
- **Title:** "ScreenCaptureKit Permissions and Basic Screen Capture"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 1.3: Transparent Overlay NSWindow
**Deliverables:**
- [ ] Transparent NSWindow creation (borderless, statusBar level)
- [ ] Display on all Spaces configuration
- [ ] Top-level display (orderFrontRegardless)
- [ ] Basic mouse event handling

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-1-3.html`
- **Title:** "Transparent Overlay NSWindow System Construction"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 1.4: Unit Testing and CI Setup
**Deliverables:**
- [ ] XCTest test target configuration
- [ ] Basic test case writing
- [ ] GitHub Actions Swift CI workflow
- [ ] Test coverage measurement

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-1-4.html`
- **Title:** "Unit Testing and GitHub Actions CI/CD Setup"
- **Deploy:** Immediately upon checkpoint completion

**🎉 Upon Milestone 1 Completion:**
- **Major PR Creation:** `feature/milestone-1-core-infrastructure` → `develop`
- **GitHub Release:** `v0.1.0`
- **Comprehensive Report:** `/docs/milestones/milestone-1.html`

### 🎯 Milestone 2: Zoom & Annotation Core
**Branch:** `feature/milestone-2-zoom-annotation`

#### Checkpoint 2.1: Real-time Screen Magnification
**Deliverables:**
- [ ] Mouse position-based zoom in/out logic
- [ ] Metal/CoreGraphics performance comparison and selection
- [ ] Smooth scaling animation
- [ ] Zoom ratio limit configuration

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-2-1.html`
- **Title:** "Real-time Screen Magnification Engine Implementation"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 2.2: NSBezierPath Drawing System
**Deliverables:**
- [ ] mouseDown/mouseDragged/mouseUp event handling
- [ ] Real-time drag trajectory storage
- [ ] NSBezierPath rendering optimization
- [ ] Memory-efficient Path management

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-2-2.html`
- **Title:** "NSBezierPath Real-time Pen Drawing System"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 2.3: Global Shortcut Implementation
**Deliverables:**
- [ ] Carbon RegisterEventHotKey implementation
- [ ] Sandbox environment operation verification
- [ ] Basic shortcut configuration (zoom/annotation mode)
- [ ] System shortcut conflict prevention

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-2-3.html`
- **Title:** "Carbon RegisterEventHotKey and Global Shortcuts"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 2.4: Basic UI/UX Completion
**Deliverables:**
- [ ] Status display UI (zoom mode, drawing mode)
- [ ] Basic toolbar or context menu
- [ ] Keyboard shortcut guide
- [ ] Basic user interaction polishing

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-2-4.html`
- **Title:** "User Interface and Interaction Design"
- **Deploy:** Immediately upon checkpoint completion

**🎉 Upon Milestone 2 Completion:**
- **Major PR Creation:** `feature/milestone-2-zoom-annotation` → `develop`
- **GitHub Release:** `v0.2.0`
- **Comprehensive Report:** `/docs/milestones/milestone-2.html`

### 🎯 Milestone 3: Advanced Features
**Branch:** `feature/milestone-3-advanced`

#### Checkpoint 3.1: Text Annotation System
**Deliverables:**
- [ ] Inline text input using NSTextField
- [ ] Text box position adjustment and resizing
- [ ] Font size, color selection features
- [ ] Text annotation save and edit

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-3-1.html`
- **Title:** "NSTextField Text Annotation System Implementation"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 3.2: Presentation Timer
**Deliverables:**
- [ ] Countdown/count-up timer implementation
- [ ] Timer overlay UI design
- [ ] Time setting and alarm features
- [ ] Timer pause/restart functionality

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-3-2.html`
- **Title:** "Presentation Timer and Alarm System"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 3.3: SwiftUI Settings UI
**Deliverables:**
- [ ] SwiftUI settings window implementation
- [ ] Shortcut customization interface
- [ ] Pen tool default settings
- [ ] AppKit ↔ SwiftUI data binding

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-3-3.html`
- **Title:** "SwiftUI and AppKit Hybrid Settings UI"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 3.4: Various Pen Tools
**Deliverables:**
- [ ] Color palette UI implementation
- [ ] Pen thickness adjustment slider
- [ ] Highlighter, eraser tool addition
- [ ] Tool-specific NSBezierPath style application

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-3-4.html`
- **Title:** "Various Pen Tools and Color System"
- **Deploy:** Immediately upon checkpoint completion

**🎉 Upon Milestone 3 Completion:**
- **Major PR Creation:** `feature/milestone-3-advanced` → `develop`
- **GitHub Release:** `v0.3.0`
- **Comprehensive Report:** `/docs/milestones/milestone-3.html`

### 🎯 Milestone 4: Polish & Testing
**Branch:** `feature/milestone-4-polish`

#### Checkpoint 4.1: Performance Optimization
**Deliverables:**
- [ ] Memory usage <50MB achievement
- [ ] Zoom response time <100ms optimization
- [ ] CPU usage <30% tuning
- [ ] Performance profiling via Instruments

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-4-1.html`
- **Title:** "Instruments Performance Profiling and Optimization"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 4.2: Comprehensive Testing
**Deliverables:**
- [ ] Unit test coverage 80%+ achievement
- [ ] UI test automation (XCUITest)
- [ ] Edge case test scenarios
- [ ] Memory leak testing

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-4-2.html`
- **Title:** "XCTest and XCUITest Comprehensive Testing"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 4.3: TestFlight Beta
**Deliverables:**
- [ ] TestFlight beta build creation
- [ ] Internal tester group formation
- [ ] Beta feedback collection system
- [ ] Crash report monitoring

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-4-3.html`
- **Title:** "TestFlight Beta Testing and Feedback Collection"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 4.4: App Store Metadata
**Deliverables:**
- [ ] App Store screenshot creation
- [ ] App description and keyword optimization
- [ ] Privacy policy writing
- [ ] Marketing materials completion

**�� Document Update:**
- **File:** `/docs/progress/checkpoint-4-4.html`
- **Title:** "App Store Metadata and Marketing Materials"
- **Deploy:** Immediately upon checkpoint completion

**🎉 Upon Milestone 4 Completion:**
- **Major PR Creation:** `feature/milestone-4-polish` → `develop`
- **GitHub Release:** `v0.9.0`
- **Comprehensive Report:** `/docs/milestones/milestone-4.html`

### 🎯 Milestone 5: App Store Launch
**Branch:** `release/v1.0.0`

#### Checkpoint 5.1: Code Signing and Archive
**Deliverables:**
- [ ] Apple Distribution certificate setup
- [ ] Production provisioning profile
- [ ] Xcode Archive build creation
- [ ] Code signing verification

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-5-1.html`
- **Title:** "Apple Distribution Code Signing and Archive"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 5.2: App Store Connect Upload
**Deliverables:**
- [ ] App Store Connect app registration
- [ ] Build upload and verification
- [ ] Metadata final review
- [ ] Review submission preparation

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-5-2.html`
- **Title:** "App Store Connect Upload and Review Submission"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 5.3: Review Response
**Deliverables:**
- [ ] Apple review team feedback response
- [ ] Rejection fix implementation
- [ ] Resubmission process management
- [ ] Approval waiting and monitoring

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-5-3.html`
- **Title:** "Apple App Review Process and Response Strategy"
- **Deploy:** Immediately upon checkpoint completion

#### Checkpoint 5.4: Marketing Materials Completion
**Deliverables:**
- [ ] Official website launch
- [ ] Social media account creation
- [ ] Press release writing
- [ ] Launch event planning

**📝 Document Update:**
- **File:** `/docs/progress/checkpoint-5-4.html`
- **Title:** "Magnify Launch Marketing and Promotion Strategy"
- **Deploy:** Immediately upon checkpoint completion

**🎉 Upon Milestone 5 Completion:**
- **Major PR Creation:** `release/v1.0.0` → `main`
- **GitHub Release:** `v1.0.0` (official release)
- **Comprehensive Report:** `/docs/milestones/milestone-5.html`
- **🚀 App Store Launch Complete!**

## Checkpoint GitHub Pages Update Strategy

### GitHub Actions Workflow Strategy:
**Workflow File Location:** `.github/workflows/`

**Required Workflows:**
1. **`pages-deploy.yml`** - GitHub Pages auto deployment (triggered per checkpoint)
2. **`swift-ci.yml`** - Swift code build and test (all commits)
3. **`checkpoint-report.yml`** - Auto document generation upon checkpoint completion

**GitHub Pages Auto Deployment Setup:**
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

**Deployment Status Monitoring:**
- **Real-time Check:** `gh run watch` (real-time log during workflow execution)
- **Deployment Completion Check:** `gh run list --limit 5` (recent 5 execution results)
- **Failure Debugging:** `gh run view --log` (failed workflow log check)

### Branch Strategy:
- **main:** Stable release branch + GitHub Pages source
- **develop:** Development integration branch  
- **feature/milestone-1-core-infrastructure:** Feature branch per milestone
- **hotfix/*:** Urgent fixes

## Critical Patterns & Conventions
- **Architecture:** MVC pattern (AppKit-based) + MVVM (SwiftUI settings)
- **Window Management:** 
  - Transparent NSWindow (borderless, .statusBar level)
  - collectionBehavior = [.canJoinAllSpaces] (display on all Spaces)
  - orderFrontRegardless() (top-level display)
- **Screen Capture Strategy:**
  - Primary: ScreenCaptureKit (macOS 12.3+)
  - Fallback: CGWindowListCreateImage (legacy support)
  - Screen recording permission required (com.apple.security.screen-capture)
- **Drawing Implementation:**
  - Override mouseDown/mouseDragged/mouseUp in NSView subclass
  - Store real-time drag trajectory in array then render with NSBezierPath
  - Utilize CALayer or Metal texture for GPU acceleration
- **Global Hotkeys:** RegisterEventHotKey (works in sandbox environment)
- **Performance Requirements:**
  - Zoom response time: <100ms
  - Memory usage: <50MB
  - CPU usage: <30% during real-time drawing

## Constraints
- **App Store Compliance:**
  - App Sandbox mandatory activation
  - Screen recording permission (Screen Recording) requires user approval
  - Code signing: Apple Distribution certificate
  - Entitlements: com.apple.security.screen-capture
- **Compatibility:** macOS 12.3+ (ScreenCaptureKit requirement)
- **Security:**
  - Global shortcut handling within sandbox
  - User privacy permission guidance UI mandatory
  - Fixed bundle ID: com.jayleekr.magnify
- **Distribution Strategy:**
  - Phase 1: Free distribution (user acquisition)
  - Phase 2: Add in-app purchases (premium features)
  - Phase 3: App-wide paid conversion (new users only)

## Success Metrics

### 🎯 Checkpoint Performance Indicators
- **Daily Progress Rate:** Complete each checkpoint within 2-3 days
- **Documentation Quality:** 95%+ technical documentation completeness per checkpoint
- **GitHub Pages Update:** Deploy within 24 hours after checkpoint completion
- **Code Quality:** 100% build success rate per checkpoint

### 📈 Milestone Performance Indicators
- **Milestone 1:** Basic infrastructure construction, 60%+ test coverage
- **Milestone 2:** Core feature implementation, performance benchmark achievement
- **Milestone 3:** Advanced feature completion, UI/UX polishing
- **Milestone 4:** Quality assurance, TestFlight preparation complete
- **Milestone 5:** App Store launch success

### 🏆 Final Success Indicators
- **Technical:** Zoom response <100ms, memory <50MB, crash rate <0.1%
- **User:** App Store rating 4.5+, 100+ reviews
- **Revenue:** Phase 2 monthly $1,000+, Phase 3 monthly $5,000+
- **Growth:** Monthly downloads 1,000+, 70%+ active users
- **📊 Development Documentation:** Total 20 checkpoint documents, 500+ average views
- **🌟 GitHub Pages:** Monthly visitors 1,000+, tech community exposure

## Tokenization Settings
ESTIMATE_MIN_RESPONSE_TOKENS: 150
ESTIMATE_MAX_RESPONSE_TOKENS: 800
ESTIMATE_TOKEN_LIMIT: 120000
USE_32K_CONTEXT_MODELS: false
