# Design System

## Purpose

Define the behavioral contracts for the WASP frontend design system: token ownership, component sharing, dark mode support, and visual parity between the sandbox and production services.

## Requirements

### Requirement: Single Source of Truth for Shared Tokens

The system SHALL maintain all shared CSS custom properties (color palette, dark mode, motion, typography) exclusively in `design/shared/tokens.css`. No service CSS file SHALL redefine tokens that exist in `tokens.css`.

### Requirement: Single Source of Truth for Shared Components

The system SHALL maintain shared UI components (theme toggle, buttons, logo, animations, resets) exclusively in `design/shared/base.css`. Service-specific CSS files SHALL only contain overrides and components unique to that service.

### Requirement: Sandbox Visual Parity

The system SHALL load production CSS files directly in `design/index.html` (the sandbox), so that any edit to `tokens.css`, `base.css`, or a service CSS file is reflected in the sandbox without restarting any server.

#### Scenario: Token change is visible in sandbox

WHEN a developer edits `design/shared/tokens.css`
AND reloads `http://localhost:8080/design/` in the browser
THEN the updated token values SHALL be visually applied across all sandbox views without any build step

### Requirement: Docker Build Resolves Symlinks

The system SHALL replace the `design/shared` symlink in each service's static directory with a real copy before `docker build`, and restore the symlink after the build completes. The built image SHALL contain the actual CSS files, not a broken symlink.

### Requirement: Dark Mode Support

The system SHALL support dark mode via both:
- The `[data-theme="dark"]` attribute on `<html>` (explicit user toggle)
- The `prefers-color-scheme: dark` CSS media query (system preference)

All foreground and background colors SHALL be defined as CSS custom properties that change value under these selectors.

### Requirement: Responsive Layout

The system SHALL render usably on viewports narrower than 480px. No fixed-width layout SHALL overflow horizontally on mobile screens.

### Requirement: Sandbox Coverage

The sandbox at `design/index.html` SHALL include all views: `home`, `test`, `profile`, and `login`, with mock data sufficient to visually validate each component state (idle, running, pass, fail, error).
