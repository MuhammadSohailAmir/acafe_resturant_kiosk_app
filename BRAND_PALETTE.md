# A/CAFÉ Brand Palette — Canonical Tokens

Single source of truth for the A/CAFÉ suite (user web app, kiosk, kitchen, backend admin/branch).
Maroon (`#971B2F` and variants `#6B1422`, `#F5E8EA`, `#3D2B2B`) has been **removed** in favour of a
near-black primary + warm beige + tan accent identity. Source of truth: the Flutter user web app
theme (`lib/theme/brand_colors.dart`).

| Token | Hex | Usage |
|---|---|---|
| brand-bg | `#E8E6DF` | Warm beige page background |
| brand-surface | `#FFFFFF` | Cards, panels, modals |
| brand-surface-alt | `#FAF7F1` | Alt rows, hover backgrounds (Flutter: `BrandColors.primaryLight`) |
| brand-primary | `#2B2B2B` | Primary buttons, primary text, logo (near-black) — was maroon `#971B2F` |
| brand-primary-hover | `#1A1A1A` | Primary hover (Flutter: `BrandColors.primaryDark`) — was `#6B1422` |
| brand-accent | `#C8A97E` | Links, highlights, active states (warm tan) — Flutter: `BrandColors.secondary` |
| brand-accent-hover | `#B8966A` | Accent hover |
| brand-border | `#E8E2D5` | Borders, dividers, input outlines |
| brand-muted | `#8A8275` | Secondary text, helpers |
| brand-success | `#5A8F5A` | Success / ready states |
| brand-warning | `#D4A24C` | Warning / warning timers (warm amber) |
| brand-danger | `#B85450` | Destructive / late orders (desaturated red — NOT maroon) |
| brand-info | `#6B8AA8` | Info states |

## Notes
- **Background** is the established suite beige `#E8E6DF` (already brand-correct and used identically
  across all four repos), rather than the `#F5F1EA` placeholder from the brief — chosen for cross-repo
  consistency. The lighter `#FAF7F1` is used as `surface-alt`.
- **Accent** is `#C8A97E` (warm tan). Primary brand colour is near-black; the tan accent appears on
  active nav / highlights / review stars (backend) and via `BrandColors.secondary` (Flutter).
- Per-repo source-of-truth files:
  - Flutter (user web / kiosk / kitchen): `lib/theme/brand_colors.dart` (+ `light_theme.dart`, `custom_theme_colors.dart`)
  - Backend: `public/assets/admin/css/style.css` `:root` block (loaded by admin **and** branch panels)
