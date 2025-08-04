# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Phoenix Framework blog/portfolio website for jola.dev. It uses NimblePublisher to serve static blog posts from markdown files, without a database backend.

## Development Commands

* THE APP IS ALREADY RUNNING AT http://localhost:5554

### Setup and Installation
```bash
mix setup          # Install and setup dependencies
mix assets.setup   # Install Node dependencies (Tailwind, Esbuild)
mix deps.get       # Install Elixir dependencies
```

### Running the Application (DON'T DO THIS)
```bash
mix phx.server              # Start Phoenix server on port 5554
iex -S mix phx.server       # Start server with interactive shell
```

### Asset Management
```bash
mix assets.build    # Build frontend assets
mix assets.deploy   # Build and minify assets for production
```

### Testing and Code Quality
```bash
mix test                    # Run all tests
mix format                  # Format Elixir code
mix credo --strict          # Static code analysis
```

## Architecture Overview

### Core Components

1. **Blog System** (`lib/jola_dev/blog/`)
   - `Blog` module uses NimblePublisher to parse markdown posts from `priv/posts/YYYY/`
   - `Post` struct defines required fields: id, author, title, body, description, tags, date
   - `MarkdownConverter` applies Tailwind CSS classes during markdown processing
   - Posts follow naming convention: `YYYY/MM-DD-slug-title.md`

2. **Web Layer** (`lib/jola_dev_web/`)
   - Simple route structure: `/` (about), `/posts`, `/projects`, `/talks`
   - `BlogController` handles blog post display
   - `PageController` serves static pages
   - Custom plugs: `HealthCheck` (at `/health`), `BlogRedirect` (handles old domain redirects)

3. **Frontend**
   - Server-side rendered with Phoenix templates (.heex files)
   - Tailwind CSS with custom markdown styling
   - Minimal JavaScript bundled with Esbuild
   - Hero icons for UI elements

### Key Patterns

- **No Database**: Static content only, no Ecto.Repo
- **Static Blog Generation**: Blog posts compiled at build time from markdown
- **Markdown Processing**: Custom pipeline with syntax highlighting via Makeup
- **Production-Ready**: Includes Sentry, health checks, Docker deployment config

### Blog Post Format

Posts must include frontmatter with:
```markdown
---
id: unique-slug
title: "Post Title"
author: "Author Name"
tags: ["tag1", "tag2"]
description: "Brief description"
---

Post content here...
```

### Testing Approach

- Use `Phoenix.ConnTest` for controller tests
- No database fixtures needed (static content)
- Test blog post rendering and routing
- Verify markdown processing and syntax highlighting

## Development Notes

- Development server runs on port 5554 (not default 4000)
- LiveDashboard available at `/dev/dashboard` in development
- Blog posts auto-reload in development via LiveReload
