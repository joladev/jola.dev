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

function initializeBubblesVotes() {
  document.querySelectorAll('#vote-on-bubbles').forEach(el => {
    const url = el.getAttribute('data-url');
    fetch(`https://bubbles.town/api/vote-count?url=${encodeURIComponent(url)}`)
      .then(r => r.json())
      .then(d => {
        if (!d.id) {
          el.remove()
          return
        }
        el.innerHTML = `
        <a href="https://bubbles.town/entry/${d.id}" class="underline" style="color: #4ecdc4" target="_blank">
          Vote on Bubbles ▲<span class="bubbles-count text-foreground pl-1">${d.count ? d.count : ''}</span>
        </a>
        `
      })
      .catch(() => el.remove());
  });
}

function initializeShelfVotes() {
  document.querySelectorAll('.vote-on-shelf').forEach(el => {
    const url = el.getAttribute('data-url') || location.href.split('#')[0];
    fetch(`https://shelf.cafe/xrpc/getItems?url=${encodeURIComponent(url)}`)
      .then(r => r.json())
      .then(d => {
        const items = d?.data?.items ?? [];
        if (!items.length) {
          el.innerHTML = `<a href="https://shelf.cafe/items/new?url=${encodeURIComponent(url)}" target="_blank" rel="noopener noreferrer" style="color:#b8623f;text-decoration:none">▲ post on shelf.cafe</a>`;
          return;
        }
        const item = el.getAttribute('data-link') === 'newest'
          ? items[0]
          : items.reduce((a, b) => (b.vote_count > a.vote_count ? b : a));
        el.innerHTML = `
        <a href="${item.shelf_url}" target="_blank" rel="noopener noreferrer" style="color:#888;text-decoration:none">
          ${item.vote_count || ''} <span style="color:#b8623f">▲</span> on shelf.cafe
        </a>`;
      })
      .catch(() => el.remove());
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initializeMobileMenu();
  initializeCodeCopy();
  initializeBubblesVotes()
  initializeShelfVotes()
});
