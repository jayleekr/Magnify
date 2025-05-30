/**
 * Magnify Development Blog - Main JavaScript
 * Jekyll 기반 macOS 화면 주석 도구 개발 블로그
 */

document.addEventListener('DOMContentLoaded', function() {
    // 페이지 로드 애니메이션
    initPageAnimations();
    
    // 진행상황 업데이트
    updateProgressBars();
    
    // 네비게이션 기능
    initNavigation();
    
    // 스크롤 기능
    initSmoothScroll();
    
    // 검색 기능 (향후 확장)
    initSearch();
});

/**
 * 페이지 로드 시 애니메이션 초기화
 */
function initPageAnimations() {
    const cards = document.querySelectorAll('.card');
    
    if (cards.length === 0) return;
    
    // 카드 애니메이션
    cards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        
        setTimeout(() => {
            card.style.transition = 'all 0.6s cubic-bezier(0.4, 0.0, 0.2, 1)';
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, index * 100);
    });
    
    // 타이틀 애니메이션
    const heroTitle = document.querySelector('.hero-title');
    if (heroTitle) {
        heroTitle.style.opacity = '0';
        heroTitle.style.transform = 'translateY(-20px)';
        
        setTimeout(() => {
            heroTitle.style.transition = 'all 0.8s ease-out';
            heroTitle.style.opacity = '1';
            heroTitle.style.transform = 'translateY(0)';
        }, 200);
    }
}

/**
 * 진행상황 바 업데이트
 */
function updateProgressBars() {
    const progressBars = document.querySelectorAll('.progress-fill');
    
    // 마일스톤별 진행률 계산 (실제 데이터는 Jekyll 변수에서 가져올 수 있음)
    const milestoneProgress = {
        'milestone-1': 25,  // Checkpoint 1.1 완료
        'milestone-2': 0,
        'milestone-3': 0,
        'milestone-4': 0,
        'milestone-5': 0
    };
    
    progressBars.forEach((bar, index) => {
        const milestoneId = `milestone-${index + 1}`;
        const progress = milestoneProgress[milestoneId] || 0;
        
        setTimeout(() => {
            bar.style.width = `${progress}%`;
        }, 500 + (index * 200));
    });
    
    // 체크포인트 상태 업데이트
    updateCheckpointStatus();
}

/**
 * 체크포인트 상태 업데이트
 */
function updateCheckpointStatus() {
    const checkpoints = document.querySelectorAll('.checkpoint-list li');
    
    // 완료된 체크포인트 (예시)
    const completedCheckpoints = ['1.1']; // Jekyll에서 동적으로 설정 가능
    
    checkpoints.forEach(checkpoint => {
        const text = checkpoint.textContent;
        const isCompleted = completedCheckpoints.some(cp => text.includes(cp));
        
        if (isCompleted) {
            checkpoint.className = 'completed';
            checkpoint.innerHTML = checkpoint.innerHTML.replace('⏳', '✅');
        }
    });
}

/**
 * 네비게이션 기능 초기화
 */
function initNavigation() {
    // 모바일 메뉴 토글 (필요시 추가)
    const navToggle = document.querySelector('.nav-toggle');
    const navMenu = document.querySelector('.nav-links');
    
    if (navToggle && navMenu) {
        navToggle.addEventListener('click', () => {
            navMenu.classList.toggle('active');
        });
    }
    
    // 활성 링크 하이라이트
    highlightActiveNavLink();
}

/**
 * 활성 네비게이션 링크 하이라이트
 */
function highlightActiveNavLink() {
    const navLinks = document.querySelectorAll('.nav-link');
    const currentPath = window.location.pathname;
    
    navLinks.forEach(link => {
        const linkPath = new URL(link.href).pathname;
        
        if (currentPath === linkPath || 
            (currentPath.includes('/blog/') && linkPath.includes('/blog/')) ||
            (currentPath.includes('/milestones/') && linkPath.includes('/milestones/'))) {
            link.classList.add('active');
        }
    });
}

/**
 * 부드러운 스크롤 기능
 */
function initSmoothScroll() {
    const anchors = document.querySelectorAll('a[href^="#"]');
    
    anchors.forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                const headerHeight = document.querySelector('.site-header').offsetHeight;
                const targetPosition = targetElement.offsetTop - headerHeight - 20;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}

/**
 * 검색 기능 초기화 (향후 확장)
 */
function initSearch() {
    // 검색 입력 필드가 있을 경우 처리
    const searchInput = document.querySelector('#search-input');
    
    if (searchInput) {
        let searchTimeout;
        
        searchInput.addEventListener('input', function() {
            clearTimeout(searchTimeout);
            
            searchTimeout = setTimeout(() => {
                performSearch(this.value);
            }, 300);
        });
    }
}

/**
 * 검색 실행 (향후 구현)
 */
function performSearch(query) {
    if (query.length < 2) return;
    
    // Jekyll Search나 Lunr.js를 사용한 검색 구현
    console.log('Searching for:', query);
}

/**
 * 카드 호버 효과 강화
 */
function enhanceCardEffects() {
    const cards = document.querySelectorAll('.card');
    
    cards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-8px) scale(1.02)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });
}

/**
 * 스크롤 시 헤더 스타일 변경
 */
function initScrollHeader() {
    const header = document.querySelector('.site-header');
    
    if (!header) return;
    
    window.addEventListener('scroll', () => {
        if (window.scrollY > 100) {
            header.style.background = 'rgba(255, 255, 255, 0.98)';
            header.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
        } else {
            header.style.background = 'rgba(255, 255, 255, 0.95)';
            header.style.boxShadow = 'none';
        }
    });
}

/**
 * 다크모드 토글 (향후 구현)
 */
function initDarkMode() {
    const darkModeToggle = document.querySelector('#dark-mode-toggle');
    
    if (darkModeToggle) {
        darkModeToggle.addEventListener('click', () => {
            document.body.classList.toggle('dark-mode');
            localStorage.setItem('darkMode', document.body.classList.contains('dark-mode'));
        });
        
        // 저장된 다크모드 설정 불러오기
        if (localStorage.getItem('darkMode') === 'true') {
            document.body.classList.add('dark-mode');
        }
    }
}

/**
 * 코드 블록 복사 기능
 */
function initCodeCopy() {
    const codeBlocks = document.querySelectorAll('pre');
    
    codeBlocks.forEach(block => {
        const copyButton = document.createElement('button');
        copyButton.className = 'copy-code-btn';
        copyButton.textContent = '복사';
        copyButton.setAttribute('aria-label', '코드 복사');
        
        copyButton.addEventListener('click', () => {
            const code = block.textContent;
            navigator.clipboard.writeText(code).then(() => {
                copyButton.textContent = '복사됨!';
                setTimeout(() => {
                    copyButton.textContent = '복사';
                }, 2000);
            });
        });
        
        block.style.position = 'relative';
        block.appendChild(copyButton);
    });
}

/**
 * 성능 최적화를 위한 이미지 지연 로딩
 */
function initLazyLoading() {
    const images = document.querySelectorAll('img[data-src]');
    
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
                observer.unobserve(img);
            }
        });
    });
    
    images.forEach(img => imageObserver.observe(img));
}

/**
 * 사용자 상호작용 트래킹 (선택적)
 */
function initAnalytics() {
    // Google Analytics나 기타 분석 도구 초기화
    // 개인정보 보호를 고려하여 구현
}

// 추가 기능들을 페이지 로드 후 초기화
window.addEventListener('load', function() {
    enhanceCardEffects();
    initScrollHeader();
    initDarkMode();
    initCodeCopy();
    initLazyLoading();
});

// 서비스 워커 등록 (PWA 기능, 선택적)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('SW registered: ', registration);
            })
            .catch(registrationError => {
                console.log('SW registration failed: ', registrationError);
            });
    });
} 