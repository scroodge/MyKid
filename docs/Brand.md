# MyKid — Brand Guidelines

MyKid is a private-first child journal. Photos are the hero; the UI must feel calm, timeless, and trustworthy.

---

## Brand Essence

**Positioning:** Private-first journal of your child’s life (Immich media + Supabase data).  
**Personality:** Calm, warm, modern, not “baby toy”.  
**Design principle:** The app should still feel right in 10 years.

---

## Logo

### Concept
A minimal line mark representing the parent–child bond, shaped into a heart / journal-like silhouette.

### Usage rules
- Prefer the **icon mark alone** for app icon / small spaces.
- Prefer the **horizontal lockup** (mark + “MyKid”) for splash screens, website headers, docs.
- Keep generous clear space: at least **1× mark stroke height** around the logo.
- Avoid drop shadows, gradients, or complex backgrounds behind the mark.
- Do not rotate, skew, outline, or add extra strokes.

### Colors for logo
- Primary: Dusty Blue `#7A9BBE`
- Neutral: Soft Charcoal `#2E2E2E`
- On dark backgrounds: use **white mark**.

---

## Color Palette

### Core
- **Warm Sand (Background):** `#F4EFEA`
- **Soft Charcoal (Text):** `#2E2E2E`

### Accents
- **Dusty Blue (Primary):** `#7A9BBE`
- **Soft Sage (Secondary):** `#9FB8A0`
- **Muted Coral (Emotional/Important):** `#E38B7A`

### UI Neutrals
- **Mist Gray (Divider/Outline):** `#D9D4CF`

### Guidance
- Photos are the hero. Use accent colors sparingly (buttons, active states, chips).
- Avoid saturated colors; avoid neon.
- Prefer subtle surfaces; low elevation.

---

## Typography

### Font families
- **Headings:** Manrope (600–700)
- **Body/UI:** Inter (400–600)
- Fallback: system sans

### Recommended hierarchy (Flutter / Material 3 aligned)
- Display / Headlines: Manrope 700
- Titles: Manrope 600
- Body: Inter 400/500
- Labels: Inter 500/600

### Guidance
- Keep line-height comfortable for journaling text.
- Prefer fewer sizes; consistent rhythm.

---

## UI Components

### App backgrounds & surfaces
- App background: Warm Sand `#F4EFEA`
- Cards/surfaces: slightly elevated, near-white tint (no harsh white blocks)
- Dividers/Outlines: Mist Gray `#D9D4CF`

### Primary actions
- FAB / primary button: Dusty Blue `#7A9BBE`
- Text on primary: white

### Children selector chips
- Default: neutral outline
- Selected: Soft Sage `#9FB8A0` (filled or tinted), with Charcoal text

### “Today” / important markers
- Use Muted Coral `#E38B7A` sparingly (badges, subtle highlights)

---

## Tone of voice (UI copy)

- Warm and simple.
- Short labels, clear verbs.
- Avoid baby-talk.
- Examples:
  - “Add photo”, “Add note”, “Choose child”, “Save entry”
  - “Today”, “Yesterday”, “No location”

---

## Do / Don’t

### Do
- Keep UI calm, let photos lead.
- Use consistent spacing and typography rhythm.
- Prefer subtle borders and soft contrast.

### Don’t
- Don’t use cartoon icons or baby stereotypes.
- Don’t overuse coral/red.
- Don’t add heavy shadows or glossy effects.

---

## Asset structure (recommended)
- `assets/brand/logo/`
- `assets/brand/app_icon/`
- `assets/brand/illustrations/` (optional)

---

## Implementation notes (Flutter)
- Use Material 3.
- Centralize colors in `lib/core/brand/mykid_colors.dart`.
- Centralize typography in `lib/core/brand/mykid_typography.dart`.
- Theme in `lib/core/brand/mykid_theme.dart`.