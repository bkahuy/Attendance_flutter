document.addEventListener('DOMContentLoaded', () => {
    const path = window.location.pathname;
    document.querySelectorAll('.nav a').forEach(a=>{
        const href = a.getAttribute('href');
        if (href && path.startsWith(href)) a.classList.add('active');
    });
});
