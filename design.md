# Design - Topsheet

A locked design system for this app. Every screen-level redesign should read
this file before applying visual changes.

## Genre
modern-minimal

## Macrostructure family
- Marketing or shell surfaces: Marquee Hero rhythm
- App form surfaces: Workbench rhythm
- Utility/settings surfaces: Long Document rhythm

## Theme
- --color-paper: oklch(98% 0.01 200)
- --color-paper-2: oklch(95% 0.02 210)
- --color-ink: oklch(22% 0.02 225)
- --color-ink-2: oklch(42% 0.02 225)
- --color-rule: oklch(82% 0.01 225)
- --color-accent: oklch(62% 0.12 188)
- --color-focus: oklch(60% 0.14 228)

## Typography
- Display: SF Pro Display (platform fallback), weight 700, style normal
- Body: SF Pro Text (platform fallback), weight 400
- Mono: SF Mono (platform fallback), weight 500
- Display tracking: -0.02em to -0.03em
- Type scale anchor: compact mobile-first, expanded desktop

## Spacing
Use a 4-point named scale. Flutter spacing should follow these token names
conceptually even when implemented as constants:

- 4, 8, 12, 16, 20, 24, 32, 40, 56

## Motion
- Easing language: ease-out cubic for arrival, ease-in-out for continuity
- Reveal pattern: minimal fade + slight translate
- Reduced motion: opacity-only, short duration

## Microinteractions stance
- Silent success by default
- No celebratory confetti/toasts
- Press feedback on pointer-down and spring return
- Focus states always visible and immediate

## CTA voice
- Primary: compact filled capsule-like action
- Secondary: tonal icon buttons with subtle border

## Per-screen allowances
- Home screen may use atmospheric background accents only
- Settings stays more restrained than Home
- Picker and suggestion sheets remain utility-first

## What screens MUST share
- Accent color family and focus color family
- Type hierarchy and tracking rhythm
- Surface radius language
- Action button voice

## What screens MAY differ on
- Section rhythm and grouping treatment
- Density based on use case
- Presence of atmospheric orbs (Home only)

## Exports

### tokens.css
```css
:root {
  --color-paper: oklch(98% 0.01 200);
  --color-paper-2: oklch(95% 0.02 210);
  --color-ink: oklch(22% 0.02 225);
  --color-ink-2: oklch(42% 0.02 225);
  --color-rule: oklch(82% 0.01 225);
  --color-accent: oklch(62% 0.12 188);
  --color-focus: oklch(60% 0.14 228);

  --space-3xs: 0.25rem;
  --space-2xs: 0.5rem;
  --space-xs: 0.75rem;
  --space-sm: 1rem;
  --space-md: 1.5rem;
  --space-lg: 2rem;
  --space-xl: 2.5rem;
  --space-2xl: 3.5rem;

  --dur-short: 120ms;
  --dur-standard: 220ms;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);

  --radius-input: 14px;
  --radius-surface: 20px;
  --radius-chip: 12px;
}
```

### Tailwind v4 @theme
```css
@theme {
  --color-paper: oklch(98% 0.01 200);
  --color-ink: oklch(22% 0.02 225);
  --color-accent: oklch(62% 0.12 188);
  --spacing-md: 1.5rem;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
}
```

### DTCG tokens.json
```json
{
  "color": {
    "paper": { "$value": "oklch(98% 0.01 200)", "$type": "color" },
    "ink": { "$value": "oklch(22% 0.02 225)", "$type": "color" },
    "accent": { "$value": "oklch(62% 0.12 188)", "$type": "color" }
  },
  "space": {
    "md": { "$value": "1.5rem", "$type": "dimension" }
  }
}
```

### shadcn/ui CSS variables
```css
:root {
  --background: 98% 0.01 200;
  --foreground: 22% 0.02 225;
  --primary: 62% 0.12 188;
  --ring: 60% 0.14 228;
  --border: 82% 0.01 225;
  --radius: 14px;
}
```
