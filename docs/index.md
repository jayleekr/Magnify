---
layout: default
title: "Magnify - macOS 화면 주석 도구 개발 여정"
description: "프레젠테이션과 강의를 위한 ZoomIt 대안을 Swift로 구현하는 9주 프로젝트"
---

<div class="home-page">
    <section class="hero">
        <div class="container">
            <h1 class="hero-title">🔍 {{ site.project.name }}</h1>
            <p class="hero-subtitle">{{ site.project.description }}</p>
            <p class="hero-description">프레젠테이션과 강의를 위한 ZoomIt 대안을 Swift로 구현하는 9주 프로젝트</p>
            
            <div class="hero-badges">
                <a href="{{ site.project.github_repo }}" class="badge github" target="_blank">GitHub Repository</a>
                <span class="badge swift">Swift 5.9+</span>
                <span class="badge appkit">AppKit</span>
                <a href="#progress" class="badge">진행상황</a>
            </div>
        </div>
    </section>
    
    <section class="content-grid">
        <div class="container">
            <div class="grid">
                <div class="card" id="project-overview">
                    <h2>🎯 프로젝트 개요</h2>
                    <p><strong>{{ site.project.name }}</strong>는 macOS에서 프레젠테이션과 강의용으로 사용할 수 있는 화면 주석 도구입니다.</p>
                    
                    <h3>핵심 기능</h3>
                    <ul>
                        <li>🔍 실시간 화면 확대/축소</li>
                        <li>✏️ 펜 도구로 화면에 주석 그리기</li>
                        <li>📝 텍스트 주석 및 하이라이트</li>
                        <li>⏱️ 프레젠테이션 타이머</li>
                        <li>⌨️ 전역 단축키 지원</li>
                        <li>🎨 다양한 펜 도구와 색상</li>
                    </ul>
                    
                    <h3>목표</h3>
                    <p>Windows ZoomIt과 동등한 기능을 제공하면서 macOS 네이티브 앱의 성능과 사용성을 구현합니다.</p>
                </div>
                
                <div class="card" id="tech-stack">
                    <h2>🛠️ 기술 스택</h2>
                    <div class="tech-grid">
                        <div class="tech-item">
                            <h4>Swift 5.9+</h4>
                            <p>주 개발 언어</p>
                        </div>
                        <div class="tech-item">
                            <h4>AppKit</h4>
                            <p>UI 프레임워크</p>
                        </div>
                        <div class="tech-item">
                            <h4>ScreenCaptureKit</h4>
                            <p>화면 캡처</p>
                        </div>
                        <div class="tech-item">
                            <h4>Metal</h4>
                            <p>GPU 가속</p>
                        </div>
                        <div class="tech-item">
                            <h4>SwiftUI</h4>
                            <p>설정 UI</p>
                        </div>
                        <div class="tech-item">
                            <h4>Carbon</h4>
                            <p>전역 단축키</p>
                        </div>
                    </div>
                </div>
                
                <div class="card progress-dashboard" id="progress">
                    <h2>🚀 개발 진행상황</h2>
                    
                    <!-- Milestone 1 -->
                    <div class="milestone" id="milestone-1">
                        <h3>Milestone 1: Core Infrastructure (Week 1-2)</h3>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: 0%"></div>
                        </div>
                        <ul class="checkpoint-list">
                            <li class="pending">⏳ Checkpoint 1.1: Xcode 프로젝트 설정</li>
                            <li class="pending">⏳ Checkpoint 1.2: ScreenCaptureKit 구현</li>
                            <li class="pending">⏳ Checkpoint 1.3: 투명 오버레이 NSWindow</li>
                            <li class="pending">⏳ Checkpoint 1.4: 단위 테스트 및 CI</li>
                        </ul>
                    </div>
                    
                    <!-- Milestone 2 -->
                    <div class="milestone" id="milestone-2">
                        <h3>Milestone 2: Zoom & Annotation Core (Week 3-4)</h3>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: 0%"></div>
                        </div>
                        <ul class="checkpoint-list">
                            <li class="pending">⏳ Checkpoint 2.1: 실시간 화면 확대/축소</li>
                            <li class="pending">⏳ Checkpoint 2.2: NSBezierPath 그리기 시스템</li>
                            <li class="pending">⏳ Checkpoint 2.3: 전역 단축키 구현</li>
                            <li class="pending">⏳ Checkpoint 2.4: 기본 UI/UX 완성</li>
                        </ul>
                    </div>
                    
                    <!-- Milestone 3 -->
                    <div class="milestone" id="milestone-3">
                        <h3>Milestone 3: Advanced Features (Week 5-6)</h3>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: 0%"></div>
                        </div>
                        <ul class="checkpoint-list">
                            <li class="pending">⏳ Checkpoint 3.1: 텍스트 주석 시스템</li>
                            <li class="pending">⏳ Checkpoint 3.2: 프레젠테이션 타이머</li>
                            <li class="pending">⏳ Checkpoint 3.3: SwiftUI 설정 UI</li>
                            <li class="pending">⏳ Checkpoint 3.4: 다양한 펜 도구</li>
                        </ul>
                    </div>
                    
                    <!-- Milestone 4 -->
                    <div class="milestone" id="milestone-4">
                        <h3>Milestone 4: Polish & Testing (Week 7-8)</h3>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: 0%"></div>
                        </div>
                        <ul class="checkpoint-list">
                            <li class="pending">⏳ Checkpoint 4.1: 성능 최적화</li>
                            <li class="pending">⏳ Checkpoint 4.2: 포괄적 테스팅</li>
                            <li class="pending">⏳ Checkpoint 4.3: TestFlight 베타</li>
                            <li class="pending">⏳ Checkpoint 4.4: App Store 메타데이터</li>
                        </ul>
                    </div>
                    
                    <!-- Milestone 5 -->
                    <div class="milestone" id="milestone-5">
                        <h3>Milestone 5: App Store Launch (Week 9)</h3>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: 0%"></div>
                        </div>
                        <ul class="checkpoint-list">
                            <li class="pending">⏳ Checkpoint 5.1: 코드 서명 및 아카이브</li>
                            <li class="pending">⏳ Checkpoint 5.2: App Store Connect 업로드</li>
                            <li class="pending">⏳ Checkpoint 5.3: 심사 대응</li>
                            <li class="pending">⏳ Checkpoint 5.4: 마케팅 자료 완성</li>
                        </ul>
                    </div>
                </div>
                
                <div class="card">
                    <h2>📅 개발 타임라인</h2>
                    <div class="timeline">
                        <div class="timeline-item">
                            <h4>Week 1-2: Core Infrastructure</h4>
                            <p>Xcode 프로젝트 설정, ScreenCaptureKit 구현, 투명 오버레이 시스템</p>
                        </div>
                        <div class="timeline-item">
                            <h4>Week 3-4: Zoom & Annotation</h4>
                            <p>실시간 확대/축소, 펜 그리기, 전역 단축키</p>
                        </div>
                        <div class="timeline-item">
                            <h4>Week 5-6: Advanced Features</h4>
                            <p>텍스트 주석, 타이머, SwiftUI 설정, 다양한 도구</p>
                        </div>
                        <div class="timeline-item">
                            <h4>Week 7-8: Polish & Testing</h4>
                            <p>성능 최적화, 테스팅, TestFlight 베타</p>
                        </div>
                        <div class="timeline-item">
                            <h4>Week 9: App Store Launch</h4>
                            <p>코드 서명, 앱스토어 업로드, 심사, 출시</p>
                        </div>
                    </div>
                </div>
                
                <div class="card">
                    <h2>🎯 성공 지표</h2>
                    <ul>
                        <li><strong>성능:</strong> 줌 응답 시간 &lt;100ms</li>
                        <li><strong>메모리:</strong> 사용량 &lt;50MB</li>
                        <li><strong>품질:</strong> 크래시율 &lt;0.1%</li>
                        <li><strong>사용자:</strong> App Store 평점 4.5+</li>
                        <li><strong>문서화:</strong> 20개 체크포인트 문서 완성</li>
                    </ul>
                </div>

                <div class="card">
                    <h2>📝 최근 포스트</h2>
                    <div class="recent-posts">
                        {% for post in site.posts limit:3 %}
                            <article class="post-preview">
                                <h3><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h3>
                                <div class="post-meta">
                                    <time>{{ post.date | date: "%Y년 %m월 %d일" }}</time>
                                    {% if post.category %}<span class="category">{{ post.category }}</span>{% endif %}
                                </div>
                                <p>{{ post.description | default: post.excerpt | strip_html | truncate: 100 }}</p>
                                <a href="{{ post.url | relative_url }}" class="read-more">자세히 보기 →</a>
                            </article>
                        {% endfor %}
                        
                        <div class="all-posts-link">
                            <a href="{{ '/blog/' | relative_url }}" class="btn btn-primary">모든 포스트 보기</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</div> 