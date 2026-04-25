# Design System

## Purpose

Define the behavioral contracts for the WASP frontend design system: token ownership, component sharing, dark mode support, and visual parity between the sandbox and production services.

## Requirements

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