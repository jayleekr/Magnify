/**
 * Magnify Development Blog - Main JavaScript
 * Jekyll-based macOS screen annotation tool development blog
 */

document.addEventListener('DOMContentLoaded', function() {
    // Page load animations
    initPageAnimations();
    
    // Update progress
    updateProgressBars();
    
    // Navigation functionality
    initNavigation();
    
    // Scroll functionality
    initSmoothScroll();
    
    // Search functionality (future expansion)
    initSearch();
});

/**
 * Initialize page load animations
 */
function initPageAnimations() {
    const cards = document.querySelectorAll('.card');
    
    if (cards.length === 0) return;
    
    // Card animations
    cards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        
        setTimeout(() => {
            card.style.transition = 'all 0.6s cubic-bezier(0.4, 0.0, 0.2, 1)';
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, index * 100);
    });
    
    // Title animation
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
 * Update progress bars
 */
function updateProgressBars() {
    const progressBars = document.querySelectorAll('.progress-fill');
    
    // Milestone progress calculation (actual data can be fetched from Jekyll variables)
    const milestoneProgress = {
        'milestone-1': 25,  // Checkpoint 1.1 completed
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
    
    // Update checkpoint status
    updateCheckpointStatus();
}

/**
 * Update checkpoint status
 */
function updateCheckpointStatus() {
    const checkpoints = document.querySelectorAll('.checkpoint-list li');
    
    // Completed checkpoints (example)
    const completedCheckpoints = ['1.1']; // Can be set dynamically from Jekyll
    
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
 * Initialize navigation functionality
 */
function initNavigation() {
    // Mobile menu toggle (add if needed)
    const navToggle = document.querySelector('.nav-toggle');
    const navMenu = document.querySelector('.nav-links');
    
    if (navToggle && navMenu) {
        navToggle.addEventListener('click', () => {
            navMenu.classList.toggle('active');
        });
    }
    
    // Highlight active link
    highlightActiveNavLink();
}

/**
 * Highlight active navigation link
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
 * Initialize smooth scroll functionality
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
 * Initialize search functionality (future expansion)
 */
function initSearch() {
    // Handle search input field if exists
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
 * Execute search (future implementation)
 */
function performSearch(query) {
    if (query.length < 2) return;
    
    // Search implementation using Jekyll Search or Lunr.js
    console.log('Searching for:', query);
}

/**
 * Enhance card hover effects
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
 * Change header style on scroll
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
 * Dark mode toggle (future implementation)
 */
function initDarkMode() {
    const darkModeToggle = document.querySelector('#dark-mode-toggle');
    
    if (darkModeToggle) {
        darkModeToggle.addEventListener('click', () => {
            document.body.classList.toggle('dark-mode');
            localStorage.setItem('darkMode', document.body.classList.contains('dark-mode'));
        });
        
        // Load saved dark mode setting
        if (localStorage.getItem('darkMode') === 'true') {
            document.body.classList.add('dark-mode');
        }
    }
}

/**
 * Code block copy functionality
 */
function initCodeCopy() {
    const codeBlocks = document.querySelectorAll('pre');
    
    codeBlocks.forEach(block => {
        const copyButton = document.createElement('button');
        copyButton.className = 'copy-code-btn';
        copyButton.textContent = 'Copy';
        copyButton.setAttribute('aria-label', 'Copy code');
        
        copyButton.addEventListener('click', () => {
            const code = block.textContent;
            navigator.clipboard.writeText(code).then(() => {
                copyButton.textContent = 'Copied!';
                setTimeout(() => {
                    copyButton.textContent = 'Copy';
                }, 2000);
            });
        });
        
        block.style.position = 'relative';
        block.appendChild(copyButton);
    });
}

/**
 * Lazy loading for performance optimization
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
 * User interaction tracking (optional)
 */
function initAnalytics() {
    // Initialize Google Analytics or other analytics tools
    // Implement with privacy considerations
}

// Initialize additional features after page load
window.addEventListener('load', function() {
    enhanceCardEffects();
    initScrollHeader();
    initDarkMode();
    initCodeCopy();
    initLazyLoading();
});

// Service worker registration (PWA functionality, optional)
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