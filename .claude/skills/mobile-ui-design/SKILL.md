---
name: mobile-ui-design
description: Design, improve, and implement professional mobile app interfaces in the existing Flutter project. Use when creating or redesigning screens, components, navigation, themes, and mobile UI experiences.
---

# Mobile UI/UX Design Skill

## Objective

Act as a senior mobile UI/UX designer and Flutter engineer. Create polished, modern, production-quality interfaces that are visually coherent, accessible, responsive, and easy to maintain.

## 1. Inspect Before Implementing

Before making changes:

- Inspect the existing project structure and architecture.
- Identify the Flutter version, dependencies, navigation, and state management.
- Review existing screens, widgets, themes, assets, and fonts.
- Understand the purpose of the screen and its user journey.
- Reuse existing business logic, controllers, repositories, and API integrations.
- Never replace the architecture or introduce dependencies without a good reason.

## 2. Design Principles

Every screen must follow these principles:

- Clear visual hierarchy and one obvious primary action.
- Modern, clean, premium-looking design.
- Consistent spacing, typography, iconography, and component styles.
- Appropriate whitespace and readable content density.
- Strong contrast and accessible touch targets.
- Responsive layouts for different mobile screen sizes.
- Thoughtful loading, empty, error, success, and disabled states.
- Subtle animations only when they improve usability.
- Avoid unnecessary decoration, excessive gradients, excessive cards, and too many competing colors.

## 3. Design System

First inspect the existing brand identity. Preserve established brand colors unless the user requests a redesign.

Define reusable design tokens for:

- Primary, secondary, background, surface, text, border, and status colors.
- Typography scale and font weights.
- Spacing scale based on a consistent 4- or 8-point grid.
- Corner radii, borders, shadows, and elevations.
- Icon sizes and touch-target dimensions.
- Animation duration and transitions.

Centralize tokens in the existing theme architecture. Avoid hardcoding repeated styles across screens.

## 4. Flutter Implementation

- Use reusable, composable widgets.
- Follow the existing architecture and state-management conventions.
- Keep business logic out of presentation widgets.
- Preserve navigation, localization, validation, and API behavior.
- Support RTL layouts and translated text where the app requires them.
- Use SafeArea, appropriate scrolling, keyboard handling, and responsive constraints.
- Avoid unnecessary rebuilds and deeply nested widget trees.
- Use existing packages before adding new dependencies.
- Never use mock data in production flows unless explicitly requested.

## 5. Screen Design Workflow

For every new or redesigned screen:

1. Understand the screen's purpose and user actions.
2. Inspect related screens and existing components.
3. Define the content hierarchy and layout.
4. Select appropriate components and visual treatments.
5. Implement the screen in the existing project.
6. Check loading, empty, error, and populated states as applicable.
7. Verify responsiveness, overflow, RTL, and accessibility.
8. Run relevant formatting, analysis, and tests.
9. Summarize the files changed and any remaining issues.

## 6. Visual Quality

Before considering a screen complete, verify:

- The first viewport communicates the screen's purpose.
- The main action is easy to find.
- Spacing and alignment are consistent.
- Text is readable and does not overflow.
- Components look like parts of one design system.
- Forms, lists, dialogs, bottom sheets, and navigation feel native to the platform.
- The screen looks intentional rather than like a collection of default widgets.

When screenshot or emulator tools are available, inspect the actual rendered screen and iterate on visual defects.

## 7. Working Rules

- Make focused changes instead of rewriting unrelated screens.
- Preserve existing functionality.
- Explain important design decisions briefly.
- Ask for clarification only when an important requirement cannot reasonably be inferred.
- Prefer implementing a complete, coherent screen over producing disconnected visual components.
- Do not claim visual verification unless a screenshot or rendered screen was actually inspected.

## Expected Result

Deliver consistent, maintainable Flutter interfaces with a professional visual identity, smooth user experience, reusable components, and working application behavior.v
| Role | Value | Use |
|---|---|---|
| brand.navy | `#0E141C` | primary surface/text, primary buttons |
| brand.blue | `#008DD2` | interactive accent, links, focus, selected state |
| brand.blueDeep | `#395EA7` | secondary accent, charts |
| success | `#009846` / bg `#E6F5EC` | positive revenue, completed, online |
| warning | fg `#B98900` / bg `#FFF6CC` | warnings — never use `#FFED00` as text/icon on white |
| danger | `#E31E24` / bg `#FFEBEE` | errors, negative amounts, overspeed |
| info | `#008DD2` / bg `#E6F4FB` | informational |
| neutral | N0 `#FFFFFF`, N50 `#F8FAFA`, N100 `#F5F5F5`, N200 `#E7EBEB`, N400 `#898989`, N600 `#626D77`, N900 `#0E141C` | surfaces, borders, text |

**Vehicle states** (map markers, chips, lists — always use the same mapping):
`moving` = success, `idle` = warning, `stopped` = brand.blueDeep, `offline` = N400, `alert` = danger.

Dark theme: background `#0F1318`, surface `#171C23`, card `#1F252E`, border `#2C343F`, text `#F2F4F6` / `#A9B2BC`; brand.blue stays the accent.

### Typography
- Latin: **Barlow**. Arabic fallback: **IBM Plex Sans Arabic** (or Cairo).
- `Digital7` only for the speedometer.
- Numbers (speed, km, money, KPIs): `fontFeatures: [FontFeature.tabularFigures()]`.

| Token | Size / weight / line-height |
|---|---|
| display | 32 / 700 / 1.2 |
| headline | 24 / 600 / 1.25 |
| titleLarge | 20 / 600 / 1.3 |
| titleMedium | 16 / 600 / 1.4 |
| bodyLarge | 16 / 400 / 1.5 |
| bodyMedium | 14 / 400 / 1.45 |
| labelLarge | 14 / 600 / 1.3 (buttons) |
| labelMedium | 12 / 500 / 1.3 |
| caption | 11 / 500 / 1.3 |

### Spacing (4-pt grid)
`xxs 4 · xs 8 · s 12 · m 16 · l 24 · xl 32 · xxl 48`
Screen gutter 16 · card padding 16 · gap between sections 24 · gap within a group 8–12.

### Radius
`xs 4` badges/chips · `sm 8` inputs/buttons · `md 12` cards · `lg 16` sheets/dialogs · `full` pills, FAB, avatars.

### Elevation
- `flat` — no shadow, 1px N200 border (lists, settings).
- `raised` — `0 2 8 rgba(0,0,0,.10)` (cards over map, KPI tiles).
- `overlay` — `0 8 24 rgba(0,0,0,.16)` (bottom sheets, dialogs).

### Icons
One icon family per project (Material Symbols Rounded preferred). Sizes 16 / 20 / 24 / 32.
PNG assets only for map markers and brand art (`assets/images/`).

## Target structure
```
lib/core/design_system/
  tokens/      ds_colors.dart ds_typography.dart ds_spacing.dart ds_radius.dart ds_elevation.dart ds_motion.dart
  theme/       app_theme.dart (light + dark from tokens) neo_colors.dart (ThemeExtension)
  components/  neo_button neo_text_field neo_card neo_stat_tile neo_status_chip neo_list_tile
               neo_section_header neo_empty_state neo_error_state neo_skeleton
               neo_bottom_sheet neo_dialog neo_app_bar neo_map_overlay_card
```
Until this exists, extend `lib/core/theme/` (`app_colors.dart`, `text_styles.dart`, `app_theme.dart`) and `lib/core/shared/` widgets rather than adding new ad-hoc styles.

## Components
- **NeoButton** — variants `primary | secondary | ghost | danger`, sizes `md (48) | lg (56)`, supports `loading`, `disabled`, leading icon. Replaces raw `ElevatedButton` and wraps `CustomElevatedButton`.
- **NeoTextField** — wraps `CustomTextField`; label above, helper/error below, 8 radius, focus border brand.blue 2px.
- **NeoCard** — `flat | raised`, radius md, padding m.
- **NeoStatTile** — icon + label + tabular value + optional delta (success/danger).
- **NeoStatusChip** — driven by the vehicle-state enum.
- **Feedback** — use `CustomSnackBar.success/error/warning/info`; no direct `ScaffoldMessenger` / `Get.snackbar`.
- **States** — `NeoSkeleton` (built on `ShimmerLoading`), `NeoEmptyState`, `NeoErrorState` with retry.

## Navigation
Build home tabs from a single permission-filtered `List<HomeTab>` (id, icon, label, builder) instead of index arithmetic based on `hasWalletPermission`. Order: Accueil → Map → Wallet (if permitted) → Help.

## Responsiveness
Avoid threading `isSmallScreen` through constructors. Read breakpoints from a `BuildContext` extension (compact < 360 dp, regular < 600 dp, expanded ≥ 600 dp).

## Workflow when changing UI
1. Read the target screen and its controller first; keep business logic untouched.
2. Replace inline styles with tokens/components; don't introduce new one-off values.
3. Split files over ~500 lines into widgets under the feature's `presentation/widgets/`.
4. Check light, dark, French, and Arabic (RTL), and a small screen (360 dp).
5. Run `flutter analyze` before finishing.
