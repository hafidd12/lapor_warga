---
name: Lapor Warga
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#414844'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#717973'
  outline-variant: '#c1c8c2'
  surface-tint: '#3f6653'
  primary: '#012d1d'
  on-primary: '#ffffff'
  primary-container: '#1b4332'
  on-primary-container: '#86af99'
  inverse-primary: '#a5d0b9'
  secondary: '#57615c'
  on-secondary: '#ffffff'
  secondary-container: '#d8e2dc'
  on-secondary-container: '#5b6560'
  tertiary: '#002d1b'
  on-tertiary: '#ffffff'
  tertiary-container: '#00452d'
  on-tertiary-container: '#74b392'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c1ecd4'
  primary-fixed-dim: '#a5d0b9'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#274e3d'
  secondary-fixed: '#dbe5df'
  secondary-fixed-dim: '#bfc9c3'
  on-secondary-fixed: '#151d1a'
  on-secondary-fixed-variant: '#3f4945'
  tertiary-fixed: '#b0f1cc'
  tertiary-fixed-dim: '#94d4b1'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#0c5136'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  button:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 64px
  max-width: 1200px
---

## Brand & Style
The design system for this community reporting platform is built on the principles of **Modern Minimalism** with a focus on civic duty and environmental stewardship. The brand personality is professional, reliable, and transparent, aimed at fostering trust between citizens and local authorities. 

The aesthetic leverages high-quality typography and generous whitespace to reduce cognitive load during the reporting process. It utilizes a card-based architecture to organize information into digestible units, ensuring the interface feels organized even when handling complex data. The emotional goal is to evoke a sense of calm efficiency and community pride.

## Colors
The palette is rooted in an environmental narrative. The **Primary** color (Deep Forest Green) provides an authoritative and grounded foundation for navigation and primary actions. The **Tertiary** (Fresh Leaf Green) is used for accents and success states to maintain the environmental theme.

**Backgrounds** utilize a Soft Earthy tone—a very light beige-gray—to differentiate the UI from standard "clinical" white apps, providing a warmer, more community-focused feel. 

**Status Colors** are strictly defined for priority reporting:
- **High Priority:** A muted, professional red to signal urgency without causing panic.
- **Medium Priority:** A warm amber for awareness.
- **Low Priority:** A soft mint green for routine maintenance or resolved issues.

## Typography
This design system employs **Inter** for its exceptional legibility and systematic feel. The scale is designed to create a clear information hierarchy:
- **Headlines** use tighter letter-spacing and heavier weights to command attention on report titles.
- **Body Text** maintains a generous line height to ensure readability for long incident descriptions.
- **Labels** utilize uppercase styling for metadata (e.g., timestamps, category tags) to distinguish them from user-generated content.

## Layout & Spacing
The layout follows a **Fixed Grid** philosophy for desktop to maintain a centered, readable column of information, while transitioning to a **Fluid Grid** for mobile devices. 

- **Mobile:** 4-column grid with 16px margins.
- **Desktop:** 12-column grid with a maximum content width of 1200px.
- **Spacing Rhythm:** Based on a 4px baseline, with 16px (md) being the standard padding for cards and containers to create a balanced, airy feel.

## Elevation & Depth
Depth is created through **Tonal Layering** and **Ambient Shadows**. Instead of heavy borders, the design system uses soft, diffused shadows with a slight green tint in the "Umbra" to maintain color harmony.

- **Level 0 (Surface):** The background color (Secondary/Neutral).
- **Level 1 (Cards):** White background with a 4% opacity shadow, 12px blur, and 4px vertical offset.
- **Level 2 (Active/Floating):** White background with an 8% opacity shadow, 24px blur, and 8px vertical offset, used for modals or active report filters.

## Shapes
The shape language is approachable and modern. A standard radius of **12px to 16px** is applied to all primary containers and cards to soften the professional tone. 
- **Small components** (Inputs, Buttons) utilize 8px (rounded).
- **Large components** (Cards, Modals) utilize 16px (rounded-xl).
- **Status Badges** utilize a full pill shape to distinguish them from interactive buttons.

## Components
- **Buttons:** Primary buttons use the Deep Forest Green background with white text. Secondary buttons use a light version of the Tertiary green with Forest Green text. Shape is `rounded`.
- **Inputs:** Fields use a subtle 1px border in the Secondary color, moving to a 2px Deep Forest Green border on focus. Backgrounds should be pure white.
- **Cards:** The core of the UI. Cards must have 16px internal padding, a 16px corner radius, and the Level 1 Ambient Shadow.
- **Status Badges:** Compact pill-shaped labels. The background should be a 15% opacity version of the status color (Red/Yellow/Green) with the text in a darker, high-contrast version of that same hue.
- **Progress Trackers:** Vertical stepped indicators for report status (Submitted -> Processed -> Resolved), using the Primary color for completed steps.