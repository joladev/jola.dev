// Mobile menu toggle
function initializeMobileMenu() {
  const menuButton = document.querySelector('[data-mobile-menu-button]');
  const mobileMenu = document.querySelector('[data-mobile-menu]');

  if (!menuButton || !mobileMenu) return;

  menuButton.addEventListener('click', () => {
    const isOpen = mobileMenu.classList.contains('open');
    if (isOpen) {
      mobileMenu.classList.remove('open');
      menuButton.setAttribute('aria-expanded', 'false');
    } else {
      mobileMenu.classList.add('open');
      menuButton.setAttribute('aria-expanded', 'true');
    }
  });

  document.addEventListener('click', (event) => {
    if (!menuButton.contains(event.target) && !mobileMenu.contains(event.target)) {
      mobileMenu.classList.remove('open');
      menuButton.setAttribute('aria-expanded', 'false');
    }
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && mobileMenu.classList.contains('open')) {
      mobileMenu.classList.remove('open');
      menuButton.setAttribute('aria-expanded', 'false');
    }
  });
}

// Copy button for code blocks
function initializeCodeCopy() {
  document.querySelectorAll('pre.lumis').forEach(pre => {
    if (pre.parentElement.classList.contains('code-wrapper')) return;

    const wrapper = document.createElement('div');
    wrapper.className = 'code-wrapper';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    const btn = document.createElement('button');
    btn.className = 'copy-btn';
    btn.setAttribute('aria-label', 'Copy code');
    btn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>`;

    btn.addEventListener('click', () => {
      const code = pre.querySelector('code').textContent;
      navigator.clipboard.writeText(code).then(() => {
        btn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>`;
        btn.classList.add('copied');
        setTimeout(() => {
          btn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>`;
          btn.classList.remove('copied');
        }, 1500);
      });
    });

    wrapper.appendChild(btn);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initializeMobileMenu();
  initializeCodeCopy();
});
