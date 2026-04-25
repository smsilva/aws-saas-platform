# Design System — WASP Lab Frontend

Visual decisions, reusable components, and design validation flow without running the environment.

---

## 0. Sources of truth

| Layer | File | Responsibility |
|---|---|---|
| **Tokens and components** | `design/shared/tokens.css` | CSS custom properties (palette, dark mode, motion) |
| **Base components** | `design/shared/base.css` | Reset, theme-toggle, buttons, animations, logo |
| **Narrative documentation** | `docs/design-system.md` (this file) | Design decisions, trade-offs, usage guides |
| **Service-specific CSS** | `services/<svc>/app/static/<svc>.css` | Only overrides and components exclusive to the service |

### Rule

> Any visual change that affects more than one service must originate from `design/shared/`. Never edit tokens or shared components directly in service CSS files.

### File structure

```
design/
├── shared/
│   ├── tokens.css    ← edit here to change colors, dark mode, etc.
│   └── base.css      ← edit here to change theme-toggle, buttons, ripple
└── index.html        ← visualization sandbox

services/<svc>/app/static/
├── shared -> ../../../../design/shared   (git-tracked symlink, local dev)
└── <svc>.css                             (@import shared + service overrides)
```

### Docker (automatic pre-copy)

Docker BuildKit does not follow symlinks outside the build context. The `scripts/13-deploy-services` script resolves this automatically: before each `docker build` of the frontend services, it replaces the symlink with a real copy of `design/shared/`, and restores the symlink immediately after.

---

## 1. Design preferences

- Palette based on Google Material You: primary `#1A73E8`, neutral surfaces
- Mandatory dark mode support via `[data-theme]` + `prefers-color-scheme`
- All tokens centralized in `:root` inside `app.css`
- Typography: Roboto for text, Roboto Mono for code/JSON
- Large border-radius (28px) on cards, smaller (8px) on inner blocks
- Theme transitions: `250ms ease` on `background-color` and `color`
- Ripple effect on filled buttons

---

## 2. Validate design without running the environment

### Sandbox (recommended)

The `design/index.html` file is a self-contained sandbox with all screens (home, test, profile, login), mocked data, and navigation between views. The real service CSS files are loaded via absolute paths — editing `app.css` or `login.css` and reloading the browser reflects the change immediately.

**For changes to tokens or base components**, edit `design/shared/tokens.css` or `design/shared/base.css` directly — the effect is immediate in the sandbox without restarting the server.

```bash
# Required: serve from the repository root, not from design/
# Python http.server blocks "../" — /services/... paths only resolve from the root
python3 -m http.server 8080
```

Access: **http://localhost:8080/design/**

> The `@import` statements inside service CSS files resolve via the `app/static/shared -> ../../../../design/shared` symlinks, which Python http.server follows correctly.

### What the sandbox covers

| Screen | Mocked data |
|---|---|
| `home` | Avatar, name, email, tenant badge |
| `test` | 5 test cases with groups, accordion, simulated run with delay |
| `profile` | Primary claims (sub, email, name) + secondary claims |
| `login` | Floating label, email validation, error state |

### Visual checklist

- [ ] Light mode
- [ ] Dark mode
- [ ] `prefers-color-scheme: dark` (without `data-theme`)
- [ ] Narrow screen (< 480px)

---

## 3. Common components and animations

> **Location of shared components:** `design/shared/base.css`
> Components exclusive to each service remain in their respective `<svc>.css`.

| Component | Where it lives |
|---|---|
| Reset `* { box-sizing }` | `base.css` |
| `.theme-toggle` (core) | `base.css` |
| `.btn-filled` | `base.css` |
| `.btn-outlined` | `base.css` |
| `.logo-section`, `.logo-name` | `base.css` |
| `@keyframes ripple`, `card-enter` | `base.css` |
| `.ripple` (element) | Service CSS (background varies) |
| `.card` | Service CSS (shadows intentionally different) |
| `.navbar`, `.accordion`, `.claims-table` | `app.css` (tenant-frontend only) |

### 3.1 Accordion (expand/collapse)

Used in: `test.html` — test case list.

**Current behavior:**
- Click on header opens the body (`display: none → block`)
- Chevron rotates 180° (`transition: transform .2s`)
- `aria-expanded` updated for accessibility

**Smooth animation (to implement):**

```css
.accordion-body {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 200ms ease;
}
.accordion-body.open {
  grid-template-rows: 1fr;
}
.accordion-body > .accordion-body-inner {
  overflow: hidden;
}
```

Replace `display: none/block` with toggle of the `.open` class.

### 3.2 Status dot

Execution state indicator for a test.

| Class | Color | Use |
|---|---|---|
| `.status-idle` | `#dadce0` | Waiting to run |
| `.status-pass` | `#34a853` | Passed |
| `.status-fail` | `#ea4335` | Failed |

### 3.3 Badge

```
.badge-ok      /* green — HTTP 200 */
.badge-deny    /* red — HTTP 403/401 */
.badge-running /* gray — running */
```

### 3.4 Buttons

- `.btn-filled`: primary, with ripple and `filter: brightness()`
- `.btn-outlined`: secondary, hover via `background: var(--color-primary-dim)`
- `.btn-sm`: size modifier (reduced padding and font-size)

### 3.5 Copy button

Clipboard icon → checkmark for 1500ms via swap of the SVG `d` attribute.

### 3.6 Ripple

`.ripple` element injected via JS on click, animated with `scale(0→4) + opacity→0`.

---

## 4. Documentation GIF capture

### Tools

```bash
# GUI — select area and record
sudo apt install peek

# CLI
sudo apt install byzanz
byzanz-record --duration=4 --x=100 --y=200 --width=600 --height=400 output.gif
```

### Naming convention

```
docs/assets/gifs/<component>-<behavior>.gif
```

Examples:

```
accordion-expand.gif
accordion-collapse-all.gif
theme-toggle-dark.gif
status-dot-run-all.gif
copy-btn-feedback.gif
```

### Priority GIFs

- [ ] `accordion-expand.gif` — click on an item opens with animation
- [ ] `run-all-status.gif` — dots idle → running → pass/fail
- [ ] `theme-toggle.gif` — light/dark transition
- [ ] `copy-btn-feedback.gif` — clipboard → checkmark

---

## 5. Improvement backlog

| Item | Description | Priority |
|---|---|---|
| Accordion animation | Replace `display:none` with `grid-template-rows` | High |
| Skeleton loader | Animated placeholder while tests run | Medium |
| Toast notification | Feedback after "Run all" completes | Medium |
| Responsive navbar | Collapse links on mobile | Low |

---

## Formal Specification

### Purpose

Define the behavioral contracts for the WASP frontend design system: token ownership, component sharing, dark mode support, and visual parity between the sandbox and production services.

### Single Source of Truth for Shared Tokens

All shared CSS custom properties (color palette, dark mode, motion, typography) live exclusively in `design/shared/tokens.css`. No service CSS file redefines tokens that exist in `tokens.css`.

### Single Source of Truth for Shared Components

Shared UI components (theme toggle, buttons, logo, animations, resets) live exclusively in `design/shared/base.css`. Service-specific CSS files contain only overrides and components unique to that service.

### Sandbox Visual Parity

`design/index.html` (the sandbox) loads production CSS files directly, so any edit to `tokens.css`, `base.css`, or a service CSS file is reflected in the sandbox after a browser reload — no build step required.

### Docker Build Resolves Symlinks

Before `docker build`, the `design/shared` symlink in each service's static directory is replaced with a real copy. After the build, the symlink is restored. The built image contains the actual CSS files, not a broken symlink.

### Dark Mode Support

Dark mode is supported via both:
- The `[data-theme="dark"]` attribute on `<html>` (explicit user toggle)
- The `prefers-color-scheme: dark` CSS media query (system preference)

All foreground and background colors are defined as CSS custom properties that change value under these selectors.

### Responsive Layout

The layout renders usably on viewports narrower than 480px. No fixed-width layout overflows horizontally on mobile screens.

### Sandbox Coverage

The sandbox at `design/index.html` includes all views: `home`, `test`, `profile`, and `login`, with mock data sufficient to visually validate each component state (idle, running, pass, fail, error).
