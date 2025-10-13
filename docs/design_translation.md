# Design Inspiration → Product Plan

This note captures the features and visual cues we want to translate from the “AuraScan” concept into the current Flutter app. Use it as the review reference for design/PM.

---

## 1. Experience Pillars

| Concept cue | Mobile translation | Status |
| --- | --- | --- |
| Ambient LED strip signalling state | Gradient “light band” on `ScanScreen` that shifts color for Ready → Scanning → Success/Error, paired with soft haptics and chimes. | **Planned** (`scan_screen.dart`) |
| Guided card alignment with projected lines | Overlay UI while camera is active (faint lines + tip copy) to help orient the card. | **Planned** (`scan_screen.dart`) |
| Sculptural premium aesthetic | Maintain glassmorphism containers, generous spacing, rounded corners already in place. Extend to new screens/menus. | **In progress** (`home_screen.dart`, `contact_tile.dart`, etc.) |
| Digital twin (flip the card) | Store front/back images; add a “flip” card component in `ContactDetailScreen` with 3D tilt on drag. | **Planned** (new widget) |
| Intelligent prompts (completeness check) | Re-use `ParserService` confidence map to surface “Missing email?” / “Add LinkedIn?” suggestions on review + detail screens. | **Planned** (`review_screen.dart`, `contact_detail_screen.dart`) |
| Card wallets / collections | Treat Isar tags as “folders”; surface tag chips and a Collections section in Settings. | **Planned** (`home_screen.dart`, `settings_screen.dart`) |
| Actionable follow-up | Quick action banners (“Email now”, “Set reminder”) based on available fields. | **Planned** (`contact_detail_screen.dart`) |

---

## 2. Visual & Motion Guidelines

1. **Color & Light**  
   - Use the theme primary gradient as a “status glow” (Ready: soft white, Scanning: aqua wave, Success: green, Error: amber).  
   - Keep backgrounds subtle; no harsh pure whites. Use `withValues(alpha: …)` for softness.

2. **Motion**  
   - Micro-interactions under 300 ms (button taps, chip selection).  
   - Longer flows (scan progress) up to 600 ms with easing on both ends.  
   - All major transitions should combine position + opacity for premium feel (already used in Home/Review screens).

3. **Sound & Haptics**  
   - Add `HapticFeedback.lightImpact` on scan success and actionable prompts.  
   - Optional short audio chime (make togglable in Settings → Sounds).

4. **Typography & Layout**  
   - Continue using bold headlines for primary actions, medium weight for body.  
   - Maintain 20 px base padding and 16 px minimum corner radius.  
   - Use blur/glass containers for panels (see `GlassContainer` widget).

---

## 3. Feature Roadmap Snapshot

### A. vCard / CSV Export (Current)
- `VCardService` already generates multi-contact `.vcf` and `.csv`, supports import, and integrates with Settings + detail share actions.
- Documentation: `docs/vcard_implementation.md`.

### B. Upcoming Work (prioritized)
1. **Scan Experience polish**  
   - Status gradient + animated wave  
   - Overlay alignment guides  
   - Haptic/audio feedback hook
2. **Digital Twin card view**  
   - Store front/back capture  
   - Add flip animation & zoom viewer  
   - Show “scan timestamp” overlay
3. **Smart prompts**  
   - In review: surface suggestions when `confidence < threshold` or fields empty.  
   - In detail: recommended actions (email, connect, follow-up reminders).
4. **Collections & filters**  
   - Surface tags as “Card Wallets” chips on home.  
   - Add Settings page for managing tags.  
   - Consider hero animation from list tile → detail to reinforce the wallet metaphor.
5. **Settings polish**  
   - Add toggles for haptics/sounds, export area, future cloud backup slot.

### C. Deferred / Nice-to-have
- AI enrichment (auto lookup missing data) — requires backend/network.  
- CRM integrations (Salesforce/HubSpot) — future plugin/back-end work.  
- Document scanner hardware integration — out of scope for current sprint.

---

## 4. Review Checklist

- [ ] Approve visual direction (ambient gradient, glass containers, parallax card view).  
- [ ] Decide priority order for scan polish vs. digital twin vs. smart prompts.  
- [ ] Confirm export formats (vCard primary, CSV optional) meet product requirements.  
- [ ] Sign off on Settings IA (where to host export/import, future cloud toggle).  
- [ ] Review animation/haptics guidelines with design.  
- [ ] Validate accessibility (contrast, large text, haptic option).

Once approved, implementation tasks will be tracked in the project board and linked to this document.
