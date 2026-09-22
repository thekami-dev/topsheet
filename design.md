# Design - Topsheet

A locked design system for this app. Every screen-level redesign should read
this file before applying visual changes.

## Genre
dark-premium (Linear/Notion inspired)

## Macrostructure family
- Marketing or shell surfaces: Marquee Hero rhythm
- App form surfaces: Workbench rhythm
- Utility/settings surfaces: Long Document rhythm

## Theme
- --color-bg: #0B0B0F
- --color-surface: #15161B
- --color-surface-2: #1B1C22
- --color-border: #26272E
- --color-text: #F2F2F5
- --color-text-2: #9A9AA5
- --color-accent: #6C5CE7
- --color-accent-2: #8A7CF0
- --color-success: #2ECC91
- --color-error: #FF5C5C
- --color-focus: #6C5CE7

No transparency/alpha-blending on surfaces. No blur/glass effects. Flat solid
colors with subtle 1px borders for separation.

## Typography
- Font family: Inter (via google_fonts)
- Display/headline weight: 700
- Body weight: 400-500
- Display tracking: -0.02em to -0.03em

## Spacing
4, 8, 12, 16, 20, 24, 32, 40, 56

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
- Primary: solid filled accent, sharp-ish radius (12px)
- Secondary: outlined/bordered button, no fill

## Per-screen allowances
- Home screen: no atmospheric background accents — flat solid bg only
- Settings stays more restrained than Home
- Picker and suggestion sheets remain utility-first

## What screens MUST share
- Fixed accent color (#6C5CE7) — never dynamic/wallpaper-based
- Type hierarchy and tracking rhythm
- Flat surfaces, no glass/blur, no gradients on cards
- Action button voice

## What screens MAY differ on
- Section rhythm and grouping treatment
- Density based on use case

## Removed from previous design
- Dynamic Material You color extraction
- Blur orbs / atmosphere background
- Alpha-blended translucent surfaces
- Paper/light theme tokens
