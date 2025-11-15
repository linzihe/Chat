document.addEventListener('DOMContentLoaded', () => {
    const navToggle = document.querySelector('.nav-toggle');
    const menu = document.querySelector('.site-nav ul');
    const themeToggle = document.getElementById('themeToggle');
    const filterButtons = document.querySelectorAll('.filter-button');
    const posts = document.querySelectorAll('.post');

    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
    const storedTheme = localStorage.getItem('moji-theme');
    if (storedTheme === 'dark' || (!storedTheme && prefersDark.matches)) {
        document.body.classList.add('dark');
        updateThemeToggleText();
    }

    prefersDark.addEventListener('change', event => {
        if (!storedTheme) {
            document.body.classList.toggle('dark', event.matches);
            updateThemeToggleText();
        }
    });

    navToggle?.addEventListener('click', () => {
        const isOpen = menu.classList.toggle('is-open');
        navToggle.setAttribute('aria-expanded', String(isOpen));
    });

    themeToggle?.addEventListener('click', () => {
        document.body.classList.toggle('dark');
        const theme = document.body.classList.contains('dark') ? 'dark' : 'light';
        localStorage.setItem('moji-theme', theme);
        updateThemeToggleText();
    });

    function updateThemeToggleText() {
        if (!themeToggle) return;
        const isDark = document.body.classList.contains('dark');
        themeToggle.textContent = isDark ? '☀️ 日间模式' : '🌙 夜间模式';
    }

    filterButtons.forEach(button => {
        button.addEventListener('click', () => {
            filterButtons.forEach(btn => btn.classList.remove('is-active'));
            button.classList.add('is-active');
            const filter = button.dataset.filter;
            posts.forEach(post => {
                const category = post.dataset.category;
                const shouldShow = filter === 'all' || category === filter;
                post.style.display = shouldShow ? 'block' : 'none';
            });
        });
    });
});
