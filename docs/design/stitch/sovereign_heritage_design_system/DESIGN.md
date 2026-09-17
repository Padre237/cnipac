---
name: Sovereign Heritage Design System
colors:
  surface: '#f9f9fc'
  surface-dim: '#dadadc'
  surface-bright: '#f9f9fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f6'
  surface-container: '#eeeef0'
  surface-container-high: '#e8e8ea'
  surface-container-highest: '#e2e2e5'
  on-surface: '#1a1c1e'
  on-surface-variant: '#3f4850'
  inverse-surface: '#2f3133'
  inverse-on-surface: '#f0f0f3'
  outline: '#6f7881'
  outline-variant: '#bec7d2'
  surface-tint: '#006494'
  primary: '#006190'
  on-primary: '#ffffff'
  primary-container: '#007bb5'
  on-primary-container: '#fcfcff'
  inverse-primary: '#8ecdff'
  secondary: '#146e00'
  on-secondary: '#ffffff'
  secondary-container: '#8cfc6d'
  on-secondary-container: '#167500'
  tertiary: '#735c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#cfa600'
  on-tertiary-container: '#4e3d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cbe6ff'
  primary-fixed-dim: '#8ecdff'
  on-primary-fixed: '#001e30'
  on-primary-fixed-variant: '#004b71'
  secondary-fixed: '#8cfc6d'
  secondary-fixed-dim: '#71df54'
  on-secondary-fixed: '#022100'
  on-secondary-fixed-variant: '#0d5300'
  tertiary-fixed: '#ffe089'
  tertiary-fixed-dim: '#f0c100'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#574500'
  background: '#f9f9fc'
  on-background: '#1a1c1e'
  surface-variant: '#e2e2e5'
typography:
  display-lg:
    fontFamily: Source Serif 4
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Source Serif 4
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Source Serif 4
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  title-md:
    fontFamily: Public Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Public Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 28px
  label-sm:
    fontFamily: Public Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1280px
  gutter: 24px
  margin-desktop: 64px
  margin-mobile: 16px
---

## Brand & Style

This design system is built to reflect the prestige, stability, and historical significance of the National Archives of Cameroon. It balances the gravity of a sovereign institution with the clarity required for modern digital governance.

The aesthetic follows a **Corporate / Modern** direction with **Heritage Accents**. It utilizes high-quality typography and a disciplined layout to evoke a sense of permanence and trust. The visual narrative is "The Custodian": a secure, organized, and authoritative environment that treats information with the highest level of professional care.

**Key Brand Pillars:**
- **Sovereign Authority:** Drawing direct inspiration from the national seal to establish immediate legitimacy.
- **Institutional Clarity:** A minimalist structural approach that ensures complex archival data remains accessible.
- **Prestigious Reliability:** A high-contrast palette and refined serif treatments that communicate a legacy of service.

## Colors

The palette is derived directly from the National Archives seal, representing the state and its history.

- **Primary (Cerulean Blue):** Used for primary actions, header backgrounds, and navigation elements. It represents the "open sky" of knowledge and the stability of the state.
- **Secondary (Emerald Green):** Used for success states, verification badges, and growth-related metrics. It anchors the design in Cameroon’s natural heritage.
- **Tertiary (National Gold):** Reserved for high-importance highlights, warnings, and special "heritage" callouts.
- **Accent (National Red):** Used sparingly for critical alerts, primary "Accession" buttons, or to draw attention to vital historical records.
- **Neutral (State Charcoal):** A deep, near-black neutral used for body text and structural borders to maintain a grounded, formal tone.

## Typography

The typography strategy employs a "Dual-Tone" approach:
1. **Source Serif 4 (The Authority):** Used for headlines and titles. Its traditional proportions mirror the circular text of the national seal, providing a scholarly and institutional weight.
2. **Public Sans (The Utility):** Used for UI elements, data tables, and body copy. It is an "institutional" sans-serif designed for clarity and neutrality, ensuring that dense archival information is easy to consume.

**Formatting Rules:**
- Use **Sentence case** for headlines to maintain a modern, approachable tone within an authoritative framework.
- Use **All-caps with tracking** for small labels and category tags to differentiate metadata from content.

## Layout & Spacing

The layout philosophy uses a **Fixed Grid** model for desktop to evoke the feeling of a well-bound ledger or a formal document. 

- **Grid:** A 12-column grid system with 24px gutters.
- **Margins:** Large 64px margins on desktop to allow the content "room to breathe," reflecting the luxury of space found in prestigious libraries.
- **Rhythm:** An 8px linear scale (8, 16, 24, 32, 48, 64) is used for all padding and margins to ensure mathematical harmony across components.
- **Responsive Behavior:** On mobile, the grid collapses to 4 columns with 16px side margins. Large display typography should scale down to the defined mobile-specific tokens.

## Elevation & Depth

This design system uses **Tonal Layers** and **Low-contrast outlines** rather than heavy shadows. This creates a "flat-paper" aesthetic that feels archival and authentic.

- **Planes:** The background uses a very light neutral tint. Content lives on pure white cards.
- **Borders:** Use 1px solid borders in a light neutral shade (#E1E3E5) to define sections.
- **Focus States:** When an element is active, use a subtle "Inner Glow" or a 2px stroke in the Primary Blue color.
- **Depth:** Avoid multiple levels of stacking. Keep the UI shallow to reinforce the feeling of a physical document placed on a desk.

## Shapes

The shape language is defined as **Rounded**, providing a bridge between traditional sharp-edged paper documents and modern software accessibility.

- **Standard Radius:** 0.5rem (8px) for buttons, input fields, and cards.
- **Large Radius:** 1rem (16px) for major container sections.
- **Strictness:** Do not use full circles/pills except for status indicators (chips). The 8px radius maintains enough structural "corner" to feel professional and established.

## Components

### Buttons
- **Primary:** Solid Primary Blue background with white text. High contrast, 8px corner radius.
- **Secondary:** Emerald Green border with Emerald Green text. Used for "Create" or "Submit" actions.
- **Ghost:** No border, Primary Blue text. Used for secondary navigation actions.

### Input Fields
- Understated design with a subtle light gray border. 
- On focus, the border transitions to Primary Blue with a 1px thickness.
- Labels always use the **label-sm** token (Public Sans, Bold, All-caps).

### Cards
- Pure white background with a 1px border. No shadow.
- Header of the card may use a subtle top-border accent in Primary Blue or Emerald Green to categorize the content type.

### Chips/Tags
- Used for metadata (e.g., "Manuscript", "19th Century").
- High-saturation backgrounds (Primary Blue or National Gold) with small, bold text.

### Information Banners
- Institutional alerts use the National Red for "Urgent/Critical" and National Gold for "Notice/Maintenance." These span the full width of the content container.