# Done-o-saur 🦕

My daughter has ADHD, and needed some tools for remembering all the things she needed to do to get ready in the morning,
get ready for bed, etc.  I built her this app (with some help from Claude).
devices.

## What is Doneosaur?

Doneosaur helps manage daily routines by displaying task lists (morning routine, bedtime, homework, etc.) on full-screen tablet displays. Perfect for families, households, or anyone who wants visual task tracking across multiple devices.

### Key Features

- **Multiple Task Lists**: Create unlimited task lists for different routines and scenarios
- **Real-time Sync**: Live updates across all connected devices via Phoenix LiveView and PubSub
- **Automatic Scheduling**: Schedule task lists to activate at specific days and times
- **Tablet-Optimized**: Full-screen display with large fonts and touch-friendly checkboxes
- **Task Images**: Attach images to tasks for visual clarity
- **Completion Feedback**: Sound effects and animations when tasks are completed

## Development Setup

### Prerequisites

- Elixir 1.15 or later
- Erlang/OTP 24 or later
- Node.js (for asset compilation)

### Getting Started

1. **Install dependencies:**
   ```bash
   mix setup
   ```
   This will install Elixir dependencies, create and migrate the database, and build assets.

2. **Start the Phoenix server:**
   ```bash
   mix phx.server
   ```
   Or start it inside IEx for interactive development:
   ```bash
   iex -S mix phx.server
   ```

3. **Visit the application:**

   Open [`http://localhost:4000`](http://localhost:4000) in your browser.

### Common Commands

- `mix setup` - Full setup (install deps, create DB, migrate, build assets)
- `mix phx.server` - Start development server
- `mix test` - Run tests
- `mix format` - Format code
- `mix ecto.reset` - Drop, recreate, and migrate database

## Database

Doneosaur uses SQLite for data persistence, making it lightweight and easy to deploy. The database is stored in `priv/repo/` and automatically created during setup.

## Security Notice


**⚠️ Important: As of now, this application currently has NO authentication or authorization.**

Doneosaur is designed for **self-hosting on a private local network only**. Do not expose this application to the public internet without implementing proper authentication and security measures.

Ideal deployment scenarios:
- Local home network
- Private internal network
- Behind VPN or firewall

## Deployment

Ready to deploy to your home server?

Please refer to the official Phoenix deployment guides:
- [Deployment Overview](https://hexdocs.pm/phoenix/deployment.html)
- [Deploying with Releases](https://hexdocs.pm/phoenix/releases.html)

You'll need to:
1. Set the `SECRET_KEY_BASE` environment variable (generate with `mix phx.gen.secret`)
2. Configure the `DATABASE_PATH` environment variable for your production database
3. Set `PHX_HOST` to your domain
4. Build a release with `mix release`

You can use the included Dockerfile to build and release on your server

## Tech Stack

- **Phoenix Framework 1.8** - Web framework
- **Phoenix LiveView** - Real-time UI updates
- **Ecto** - Database wrapper and query DSL
- **SQLite** - Embedded database

## License

This project is available for personal and self-hosted use.
