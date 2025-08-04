# jola.dev

A Phoenix-based blog and portfolio website for jola.dev, built with Elixir and NimblePublisher for static content management.

## Overview

This project is a personal blog and portfolio site that features:
- Static blog posts generated from Markdown files
- No database dependency - all content is compiled at build time
- Server-side rendered pages with Phoenix
- Tailwind CSS for styling
- Syntax highlighting for code blocks via Makeup
- Health checks and monitoring ready for production

## Prerequisites

- Elixir 1.14 or later
- Node.js (for asset compilation)
- Mix (comes with Elixir)

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd jola_dev
   ```

2. **Install dependencies**
   ```bash
   mix setup
   ```
   This command will:
   - Install Elixir dependencies
   - Install Node.js dependencies (Tailwind, Esbuild)
   - Set up the development environment

3. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```
   Or to start with an interactive shell:
   ```bash
   iex -S mix phx.server
   ```

4. **Visit the site**

   Open your browser and navigate to [`http://localhost:5554`](http://localhost:5554)

   Note: The development server runs on port 5554, not the default Phoenix port 4000.

## Project Structure

```
jola_dev/
├── lib/
│   ├── jola_dev/           # Core application logic
│   │   └── blog/           # Blog system with NimblePublisher
│   └── jola_dev_web/       # Web layer (controllers, views, templates)
├── priv/
│   └── posts/              # Markdown blog posts organized by year
│       ├── 2019/
│       ├── 2020/
│       └── 2025/
├── assets/                 # Frontend assets (CSS, JS)
└── config/                 # Application configuration
```

## Writing Blog Posts

Blog posts are stored as Markdown files in `priv/posts/YYYY/` with the naming convention: `MM-DD-slug-title.md`

Each post must include frontmatter:

```markdown
---
id: unique-slug
title: "Your Post Title"
author: "Author Name"
tags: ["elixir", "phoenix", "web"]
description: "A brief description of your post"
---

Your post content here...
```

Posts are compiled at build time and automatically available at `/posts/slug-title`.

## Development Commands

### Running tests
```bash
mix test
```

### Formatting code
```bash
mix format
```

### Running static analysis
```bash
mix credo --strict
```

### Building assets
```bash
mix assets.build    # Build frontend assets
mix assets.deploy   # Build and minify for production
```

## Key Features

- **Static Blog Generation**: All blog posts are compiled from Markdown at build time
- **No Database**: Pure static content, no Ecto or database setup required
- **Syntax Highlighting**: Code blocks in blog posts are automatically highlighted
- **Health Checks**: Available at `/health` for monitoring
- **LiveDashboard**: Development metrics at `/dev/dashboard` (dev only)
- **Production Ready**: Includes Sentry integration and Docker deployment configuration

## Production Deployment

The application is configured for production deployment with:
- Docker support (see Dockerfile)
- Health check endpoint at `/health`
- Sentry error tracking integration
- Asset fingerprinting and caching

For deployment, ensure you set the required environment variables:
- `SECRET_KEY_BASE` - Generate with `mix phx.gen.secret`
- `PHX_HOST` - Your production domain (e.g., "jola.dev")
- `PORT` - Port to bind to (default: 4000)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
