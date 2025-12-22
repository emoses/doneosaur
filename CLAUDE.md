# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Doneosaur is a Phoenix 1.8 web application for managing recurring task lists. The application displays task lists (e.g., morning routine, bedtime, after school) on full-screen tablet displays with real-time synchronization across devices viewing the same list. Uses SQLite for data persistence.

**Key Features:**
- Multiple recurring task lists (morning routine, bedtime, returning home, etc.)
- Display assignment: different displays can be assigned to different task lists
  - Example: bathroom display shows bedtime routine, while iPad and living room show homework list
- Real-time sync via Phoenix LiveView and PubSub (all displays viewing the same list see updates)
- Full-screen, tablet-optimized display with large fonts and simple checkboxes
- Two trigger mechanisms:
  - Time-based: scheduled triggers (e.g., weekday mornings at 7:00 AM)
  - API-driven: external endpoint to display a specific named list
- Self-hosted application (no multi-tenancy or authentication required)
- Future enhancements: task images, completion sounds, progress indicators

**Target Deployment:**
- Self-hosted on local network
- Displayed on multiple tablets simultaneously (iPads, wall displays, etc.)
- Each display can be assigned to show specific task lists

## Common Commands

### Setup
- `mix setup` - Full setup: installs deps, creates/migrates DB, sets up and builds assets
- `mix deps.get` - Install dependencies only

### Development
- `mix phx.server` - Start Phoenix server (visit http://localhost:4000)
- `iex -S mix phx.server` - Start server with interactive shell

### Database
- `mix ecto.create` - Create database
- `mix ecto.migrate` - Run migrations
- `mix ecto.reset` - Drop, recreate, and migrate database
- `run priv/repo/seeds.exs` - Run seeds (after importing Ecto.Query and other supporting modules)

### Testing
- `mix test` - Run all tests (auto-creates test DB and runs migrations)
- `mix test test/path/to/test.exs` - Run specific test file
- `mix test --failed` - Rerun previously failed tests

### Assets
- `mix assets.setup` - Install esbuild
- `mix assets.build` - Compile assets (runs esbuild)
- `mix assets.deploy` - Build minified assets for production

### Quality Checks
- `mix precommit` - Run before committing: compile with warnings as errors, unlock unused deps, format code, run tests
- `mix format` - Format code

## Architecture

### Application Structure

The application follows standard Phoenix conventions:

- **`lib/doneosaur/`** - Core business logic, contexts, and Ecto schemas
  - `application.ex` - OTP application that supervises: Telemetry, Repo, DNSCluster, PubSub, Endpoint
  - `repo.ex` - Ecto repository for database access
  - `mailer.ex` - Email functionality via Swoosh

- **`lib/doneosaur_web/`** - Web interface layer
  - `endpoint.ex` - HTTP endpoint
  - `router.ex` - Route definitions with `:browser` and `:api` pipelines
  - `telemetry.ex` - Metrics and monitoring
  - `components/` - Reusable UI components (core_components.ex, layouts.ex)
  - `controllers/` - Traditional Phoenix controllers
  - `gettext.ex` - Internationalization

- **`lib/doneosaur_web.ex`** - Defines `use DoneosaurWeb, :*` macros that set up common imports/aliases for controllers, LiveViews, components, etc.

### Key Patterns

**Module Naming:**
- Web modules: `DoneosaurWeb.*` (e.g., `DoneosaurWeb.UserLive`, `DoneosaurWeb.PageController`)
- Business logic: `Doneosaur.*` (e.g., `Doneosaur.Accounts`, `Doneosaur.Products`)

**Router Scopes:**
- The `:browser` pipeline scope is aliased with `DoneosaurWeb`, so routes can reference modules directly
- Example: `live "/users", UserLive` resolves to `DoneosaurWeb.UserLive`

**Shared Imports:**
- `DoneosaurWeb.CoreComponents` is imported into all HTML contexts via `html_helpers()`
- `DoneosaurWeb.Layouts` is aliased in all HTML contexts
- `Phoenix.LiveView.JS` is aliased for client-side interactions

### Database

This project uses **SQLite** via Ecto for data persistence. SQLite is well-suited for this self-hosted, single-instance application.

### HTTP Client

This project uses **Req** (`:req` library) for all HTTP requests. Never use HTTPoison, Tesla, or httpc.

### Development Environment

- LiveDashboard available at `/dev/dashboard` (dev only)
- Mailbox preview at `/dev/mailbox` (dev only)
- Hot code reloading enabled with `Phoenix.CodeReloader`

## Domain Model & Application Architecture

### Core Entities

**Task Lists:**
- Named collections of tasks (e.g., "Morning Routine", "Bedtime", "Homework")
- Can be triggered by time-based schedules or API calls
- Persist in database with tasks, order, and metadata

**Tasks:**
- Individual items within a list (e.g., "Get dressed", "Feed cat")
- Display text (large, readable fonts)
- Future: associated images and completion sounds
- Order within the list matters

**Displays:**
- Represent physical devices (tablets, wall displays)
- Each display has an identifier
- Can be assigned to view specific task lists
- Multiple displays can view the same list simultaneously

**Task Completion State:**
- Ephemeral state (resets daily or when list is re-triggered)
- Tracks which tasks are checked/unchecked
- Synced in real-time across all displays viewing that list instance
- Broadcasts updates via PubSub to all connected LiveView clients

### LiveView Architecture

**Real-time Synchronization:**
- Use Phoenix.PubSub to broadcast task completion events
- All LiveView clients viewing the same active list subscribe to that list's topic
- When a task is checked/unchecked on any display, broadcast to `"task_list:#{list_id}"`
- All subscribed clients receive the update and re-render

**Display Routing:**
- Displays access the app via unique URLs or identifiers
- Route determines which display is viewing, which in turn determines available lists
- LiveView handles display-to-list assignment logic

**State Management:**
- Active list state stored in-memory (ETS, GenServer, or LiveView process)
- Completed task state broadcasts to all connected displays for that list
- Consider using a GenServer to manage active list sessions if needed

### Trigger System

**Time-based Triggers:**
- Use Elixir's built-in scheduler or a library like Quantum
- Configuration maps time patterns to task lists
- Example: weekday mornings at 7:00 AM → "Morning Routine" list
- Triggers activate the list, making it visible on assigned displays

**API Triggers:**
- HTTP API endpoint (JSON API pipeline) to activate lists by name
- Example: `POST /api/lists/activate` with `{"list_name": "Homework"}`
- Returns success/error response
- Makes the list visible on all displays assigned to that list

### Data Contexts

Organize business logic into contexts:

**`Doneosaur.Lists`:**
- Manages task lists and tasks
- CRUD operations for lists and tasks
- Query functions to fetch lists with tasks

**`Doneosaur.Displays`:**
- Manages display registration and assignment
- Maps displays to their assigned task lists

**`Doneosaur.Sessions`:**
- Manages active list sessions (which lists are currently showing)
- Tracks task completion state for active sessions
- Broadcasts completion events via PubSub

**`Doneosaur.Scheduler`:**
- Handles time-based list activation
- Configuration for scheduled triggers

### UI/UX Guidelines

**Display Design:**
- Full-screen layout optimized for tablets in landscape or portrait
- Large, readable fonts (extra-large text for task names)
- Simple, clean interface with minimal distractions
- High contrast for accessibility
- Large touch targets (checkboxes/buttons) for easy interaction

**Task List Display:**
- Show task list title prominently at top
- Display tasks in order with large checkboxes
- Initially: simple text + checkbox layout
- Future: task icons/images displayed alongside text

**Interactive Elements:**
- Large, touch-friendly checkboxes
- Provide immediate visual feedback on check/uncheck
- Future: play sound effect on task completion
- Future: celebration animation/sound when all tasks complete

**Progressive Enhancement:**
- Start with basic checkbox + text implementation
- Add images in a later iteration (store in database or `/priv/static/images/tasks/`)
- Add audio feedback using HTML5 audio elements and JS hooks
- Consider progress bar or completion percentage indicator

### Implementation Notes

**LiveView PubSub Pattern:**
```elixir
# In mount/3, subscribe to the active list
Phoenix.PubSub.subscribe(Doneosaur.PubSub, "task_list:#{list_id}")

# In handle_event for task toggle
Phoenix.PubSub.broadcast(
  Doneosaur.PubSub,
  "task_list:#{list_id}",
  {:task_toggled, task_id, checked}
)

# In handle_info to receive broadcasts
def handle_info({:task_toggled, task_id, checked}, socket) do
  # Update socket state and re-render
end
```

**Display Identification:**
- Use URL params (e.g., `/display/:display_id`) or query strings
- Store display_id in LiveView socket assigns
- Look up which lists this display should show
- Consider using browser local storage (via JS hooks) for persistent display ID

**Task State Storage:**
- Don't store completion state in database (it's ephemeral)
- Use ETS table, Agent, or GenServer for active session state
- Key structure: `{list_id, session_timestamp} => %{task_id => checked}`
- Sessions reset daily or when list is re-activated

**Scheduling Implementation:**
- Consider using Quantum library for cron-like scheduling
- Or use Elixir's `Process.send_after/3` with recursive scheduling
- Store schedule configuration in database
- On trigger: activate the list session and broadcast to subscribed displays

## Important Guidelines

All guidelines from AGENTS.md apply. Key reminders:

- Always run `mix precommit` after making changes to ensure code quality
- Use `to_form/2` for all forms in LiveViews, access via `@form[:field]` in templates
- Use LiveView streams (`stream/3`, `stream_delete/3`) for collections, not regular assigns
- Never use `phx-update="append"` - use streams instead
- Use `<.link navigate={...}>` and `<.link patch={...}>`, not deprecated `live_redirect`/`live_patch`
- Use `{...}` for interpolation in attributes, `<%= ... %>` for block constructs in tag bodies
- Use `cond` for multiple conditions, not `else if` (which doesn't exist in Elixir)
- Avoid LiveComponents unless specifically needed
- Give forms and key elements unique DOM IDs for testing (e.g., `id="user-form"`)
- CSS belongs in CSS files.  Use CSS variables or occasionally inline styles, but don't put CSS style blocks inline in HEEX or other
  live-rendered templates
