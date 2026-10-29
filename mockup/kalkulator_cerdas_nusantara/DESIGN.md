---
name: Kalkulator Cerdas Nusantara
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#3d4a42'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#6d7a72'
  outline-variant: '#bccac0'
  surface-tint: '#006c4a'
  primary: '#006948'
  on-primary: '#ffffff'
  primary-container: '#00855d'
  on-primary-container: '#f5fff7'
  inverse-primary: '#68dba9'
  secondary: '#006a61'
  on-secondary: '#ffffff'
  secondary-container: '#86f2e4'
  on-secondary-container: '#006f66'
  tertiary: '#006947'
  on-tertiary: '#ffffff'
  tertiary-container: '#00855b'
  on-tertiary-container: '#f5fff6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#85f8c4'
  primary-fixed-dim: '#68dba9'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#005137'
  secondary-fixed: '#89f5e7'
  secondary-fixed-dim: '#6bd8cb'
  on-secondary-fixed: '#00201d'
  on-secondary-fixed-variant: '#005049'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
  numeric-keypad:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style
The design system establishes an approachable, tactually satisfying, and precise utility interface designed specifically for everyday Indonesian digital productivity. The core aesthetic merges Modern Material 3 structural discipline with a refined tactile touch—providing immediate mechanical confirmation and computational trust. 

Targeting diverse Indonesian users—from MSME merchants (*UMKM*) calculating wholesale margins to commuters and households figuring out daily budgets, unit prices, and loan installments—the interface feels fresh, smart, and reassuringly robust. The emotional experience balances the effortless clarity of a clean canvas with the confidence of tactile physical cash registers and modern mobile banking. Every interaction evokes *hemat* (smart thriftiness), precision, and ergonomic speed under direct sunlight or one-handed transit usage.

## Colors
The palette leverages a fresh, botanical green and teal foundation rooted in the psychology of financial health, thrift, and clarity:

- **Primary (`#059669` - Emerald Forest):** Used for primary conversion points, active toggle states, primary calculate buttons, and focal currency values.
- **Secondary (`#0D9488` - Deep Teal):** Applied to secondary badges, comparison metrics, analytical graphs, and auxiliary functional controls.
- **Tertiary (`#10B981` - Mint Accent):** Reserved for positive savings highlights ("Paling Hemat"), profit gains, progress fills, and active indicator pills.
- **Neutral Base & Canvas:** The background canvas rests on `#F8FAFC` (Cool Off-White) to reduce eye fatigue, while cards, input sheets, and tactile keypads use `#FFFFFF`. High-tier body typography renders in `#0F172A` (Deep Slate Slate) with secondary metadata in `#334155` (Muted Slate) and `#64748B` (Tertiary Slate). Subtle divider borders leverage `#E2E8F0`.
- **Semantic Accents:** An energetic amber-coral (`#F59E0B` / `#EF4444`) is selectively deployed for deletion operations, clear operations (*C/AC*), and negative variances.

## Typography
Plus Jakarta Sans serves as the universal typeface across all roles, providing geometric balance with friendly humanist terminals that maximize readability on high-density mobile screens.

- **Tabular Figures:** All numeric displays (results, Rupiah currency outputs, and keypad faces) enforce tabular lining figures (`font-variant-numeric: tabular-nums;`) to prevent layout shifts during live calculations.
- **Rupiah Currency Standards:** The "Rp" prefix is displayed with distinct optical sizing—typically 2 to 4 points smaller and 1 weight tier lighter than the subsequent amount string to clearly separate label from magnitude.
- **Scalability:** Large displays adapt via `display-lg-mobile` to prevent overflow when displaying 10+ digit Indonesian Rupiah sums.

## Layout & Spacing
The layout follows an ergonomic 4-column mobile grid for smartphone viewports, expanding to 8 columns on foldables and tablets. 

- **Keypad Density:** Numeric keypads adhere to a fixed 4x4 or 4x5 grid where cells utilize `gutter: 0.75rem` to guarantee a thumb-friendly minimum tap zone of 56px height.
- **Canvas Boundaries:** Screen content is wrapped inside a persistent `margin: 1rem` safe-margin boundary that dynamically expands at larger breakpoints.
- **Vertical Hierarchy:** Calculation outputs sit inside sticky top sheets with generous internal padding (`space-xl`), while configuration fields (discounts, tax, interest sliders) flow vertically with `space-md` separation.

## Elevation & Depth
Depth is communicated through modern Material 3 tonal layering supplemented by crisp, tactile micro-shadows:

- **Surface Levels:**
  - *Base Surface (0dp):* `#F8FAFC` canvas.
  - *Resting Card Surface (1dp):* `#FFFFFF` paired with an ambient shadow: `0px 2px 8px -2px rgba(15, 23, 42, 0.06)` and a subtle `1px solid #F1F5F9` structural outline.
  - *Floating Summary Card / Bottom Bar (2dp):* `#FFFFFF` with `0px 4px 16px -4px rgba(15, 23, 42, 0.10)`.
  - *Tactile Keypad Buttons:* Keys feature a distinct mechanical tactile feel using a layered bottom rim: `box-shadow: 0 3px 0 0 #E2E8F0, 0 4px 6px -1px rgba(15, 23, 42, 0.05)`. On active tap state, the button transforms (`translateY(2px)`) with the shadow collapsing to `0 1px 0 0 #CBD5E1` to mimic physical micro-switches.
  - *Accent Action Keys:* The primary calculate/equals button applies an emerald drop shadow: `0 4px 12px 0 rgba(5, 150, 105, 0.35)`.

## Shapes
The design embraces a generous Material 3 curved aesthetic centered on `rounded-2xl` (16px / 1rem) for containers and controls:

- **Cards & Result Surfaces:** Standardized at `16px` radius (`rounded-lg` token mapping for roundedness level 2).
- **Keypad Keys:** Standardized at `12px` to `16px` for balanced pill-squircle ergonomics.
- **Highlight Badges & Switch Pills:** Fully rounded pill shapes (`9999px`) to maintain contrast with the squircle cards.
- **Bottom Navigation & Bottom Sheets:** Top corners curved at `24px` (`rounded-xl`).

## Components

### Keypad Buttons
- **Numeric Keys:** Surface `#FFFFFF`, text `#0F172A`, border `1px solid #E2E8F0`, subtle 3D base shadow.
- **Operator Keys (+, -, ×, ÷):** Surface `#F1F5F9`, text `#0D9488`, semi-bold weight.
- **Primary / Equals (=):** Full-bleed `#059669`, text `#FFFFFF`, bold weight, vibrant emerald elevation glow.
- **Clear (C / AC):** Surface `#FEF2F2`, text `#EF4444`, border `1px solid #FEE2E2`.

### Highlight Badges ("Paling Hemat" & Discount Tags)
- **Discount Badge:** High-contrast pill filled with `#ECFDF5` (Emerald Tint), text `#059669`, featuring an explicit percentage symbol prefix (e.g., `-35%`).
- **"Paling Hemat" Tag:** Prominent micro-banner pinned to the upper right of optimal cards. Pill-shaped container filled with `#10B981`, white text, accompanied by a small sparkle/check icon.

### Cards & Result Panels
- Elevated `#FFFFFF` surfaces wrapped in `16px` border-radius.
- Large Rupiah typography right-aligned or stacked with dynamic breakdown items (Subtotal, PPN 11%, Diskon, Total Akhir) segmented by dashed hairline dividers (`#E2E8F0`).

### Input Fields & Steppers
- Outlined fields with `#F8FAFC` background fill, shifting to `#FFFFFF` with `#059669` 2px border ring upon focus.
- Dedicated numeric input fields include embedded Indonesian Rupiah prefixes ("Rp") locked into secondary slate styling.

### Android Chrome & Navigation
- **Status Bar:** Transparent scrim with dark system icons matching `#0F172A`.
- **Bottom Navigation Bar:** Floating dock or anchored `#FFFFFF` bar with 24px top radius. Active tab displays an emerald indicator pill with `#059669` icon and label; inactive tabs render in `#64748B`.