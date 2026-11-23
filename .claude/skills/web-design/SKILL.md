---
name: "web-design"
description: "Design and build a great website or web page (landing page, portfolio, product, org or event site): brief, structure, visual system, build, and a quality checklist."
---

# Web Design

A working method for designing websites that look intentional *and* work: clear in five seconds, easy to read and navigate, fast, accessible, and built around one goal. Pair with `frontend-design` for extra aesthetic direction; this skill owns the process, the standards and the QA.

## 0. Where the output goes
- A design to look at, compare and edit (mockup, landing page, poster-like page): use the **Design** artifact type if it is listed.
- A working site or microsite to share: one self-contained HTML page (markup, styles, script in one file), published as an artifact.
- Raw files only if the user asks for the code or says it goes into their own site/framework.

## 1. Brief first (ask only what you can't infer, max 3 questions)
Pin down before designing:
1. **Goal** – the single most important thing a visitor should do (buy, sign up, contact, read, apply, RSVP).
2. **Audience** – who, on what device (assume mobile-first unless told otherwise), how much they already know.
3. **Content inventory** – real copy, images, logos, data. Design with real content, never lorem ipsum, or the layout lies.
4. **Personality** – 3 adjectives (e.g. calm / technical / premium). These drive type, color and motion.
5. **Constraints** – brand colors/fonts, deadline, platform, required pages.

## 2. The 10 essentials of a great website
Every design decision is checked against these:
1. **Five-second clarity** – headline says what it is and why it matters; primary CTA visible without scrolling.
2. **Visual hierarchy** – one obvious focal point per screen; size, weight, color and space rank everything else. People scan (F/Z patterns), they don't read.
3. **Simple, predictable navigation** – ≤7 top-level items, current location shown, logo links home, key links repeated in footer. Follow conventions (Jakob's Law: users expect your site to work like the others they use).
4. **Readability** – comfortable size, line length and contrast (numbers in §4).
5. **Consistency** – one token system for spacing, color, radius, type; same component looks/behaves the same everywhere.
6. **Responsive, mobile-first** – design the 375px layout first, then expand.
7. **Performance** – Core Web Vitals "good": LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1.
8. **Accessibility** – WCAG 2.2 AA as the floor (§4).
9. **Trust** – real proof (logos, testimonials, numbers, team, contact details), no dark patterns, secure forms.
10. **Purposeful minimalism** – every element earns its place; anything irrelevant competes with what matters (Nielsen heuristic #8).

Usability lens (Nielsen's 10 heuristics, short form): show system status; speak the user's language; give an exit/undo; be consistent; prevent errors; recognition over recall; shortcuts for experts; minimalist design; clear error messages; help in context.

## 3. Structure
### Information architecture
List pages → group by user task (not org chart) → name sections in the user's words → sketch a sitemap before any visuals.

### Section skeletons by site type
- **Landing / product page**: Nav (logo, ≤5 links, 1 CTA) → Hero (headline ≤10 words, 1–2 line subhead, primary + secondary CTA, product visual) → Proof strip (logos/rating) directly under CTA → Problem/benefit → Features (bento grid, 6–9 tiles max) → How it works (3 steps) → Testimonials/case study → Pricing → FAQ (objections) → Final CTA → Footer. Repeat a contextual CTA after each major section.
- **Portfolio**: Name + one-line positioning → 3–6 selected works (outcome first, then process) → About → Contact. Personality can be loud here.
- **Organization / event / school project**: Hero with what/when/where → key info cards → schedule/details → people → location/map → register/contact.
- **Content / blog / docs**: Search + clear categories, readable article column, table of contents, related links.
- **Task / service (gov-style)**: Search front and centre, plain language, big type, underlined links, no decoration that slows the task.

## 4. Visual system (define as CSS custom properties before building)

| Token | Default |
|---|---|
| Body text | 16–20px (gov.uk uses 19px), line-height 1.5–1.6 |
| Line length | 45–75 characters, ~66 ideal → `max-width: 65ch` |
| Type scale | ratio 1.2–1.333, fluid with `clamp()`; hero 48–72px desktop |
| Headings | tight line-height 1.0–1.2, slight negative tracking (−0.02em) on large sizes |
| Fonts | max 2 families (often 1 variable font); system stack fallback |
| Spacing | 4/8px base scale: 4, 8, 12, 16, 24, 32, 48, 64, 96, 128 |
| Section padding | 64–128px desktop, 48–64px mobile |
| Grid | 12 columns desktop, 4 mobile; max content width 1120–1280px |
| Color | 1 brand/accent + neutrals (8–10 step grey ramp) + semantic (success/warn/error). 60-30-10 rule. Accent reserved for CTAs and key highlights |
| Contrast | text ≥ 4.5:1; large text (≥24px, or ≥18.66px bold) ≥ 3:1; UI parts and icons ≥ 3:1. Never round up (4.47:1 fails) |
| Tap targets | ≥ 24×24px (WCAG 2.2 AA); aim 44×44px for main buttons/touch |
| Buttons | 44–48px tall, 16–24px horizontal padding; one primary style per view |
| Radius | pick one family: sharp (0–4px), soft (8–12px) or pill (999px) and stick to it |
| Motion | micro-interactions 150–300ms, ease-out; larger transitions ≤ 500ms |

Dark mode: not pure black (use ~#0a0b0c) and not pure white text (~#f5f5f5); lower saturation for accents; secondary text as mid-grey still passing 4.5:1.

## 5. Patterns from studied sites (Nov 2026)
- **Linear (SaaS, dark)** – near-black #08090a background, one variable sans (Inter) at a medium 510 weight, 64px hero with negative tracking, secondary copy in muted grey #8a8f98, the real product UI as the hero visual, respects `prefers-reduced-motion`. Lesson: restraint + one great product shot beats decoration.
- **Stripe (fintech)** – two-tone headline (dark first sentence, muted continuation) so one block reads as headline + subhead; light 300 weight display type; live counter as proof; logo strip directly under the 48px primary + secondary CTAs; vivid gradient art confined to one side. Lesson: stage proof right after the ask.
- **Apple (product)** – centered product name + one-line promise + two 44px pill CTAs (filled + outline), then huge product imagery in stacked tiles. Lesson: one product per screen, image does the selling.
- **GOV.UK (task/service)** – 19px body, underlined links, skip link, search as the main action, cookie banner where Reject is as prominent as Accept. Lesson: for task sites, clarity and accessibility *are* the design.
- **Lando Norris site (Awwwards Site of the Year 2025)** – immersive WebGL/canvas, layered scroll storytelling, bold condensed variable type, playful brand texture. Lesson: spectacle suits personal brands and campaigns; never for task or conversion-critical pages.

## 6. Trends – adopt, test, skip
- **Adopt**: bento grids for feature sections; bold typographic heroes; native CSS scroll-driven animations (run on compositor, now cross-browser); View Transitions for page changes; micro-interactions on every interactive element; dark/light theming; clean semantic structure that AI search agents can read.
- **Test**: scrollytelling, 3D/WebGL, kinetic type, grain/texture, glassmorphism – only if performance and readability survive.
- **Skip**: scroll-jacking, auto-playing carousels, neo-brutalism where conversion depends on legibility, cursor-follow effects that hide the pointer, splash/intro loaders.

## 7. Build rules
- Semantic HTML: one `<h1>`, ordered headings, `<header> <nav> <main> <section> <footer>`, real `<button>`/`<a>`, labels on every input.
- Skip-to-content link; visible `:focus-visible` ring (2–3px, ≥3:1).
- Images: explicit `width`/`height` or `aspect-ratio` (prevents CLS), `loading="lazy"` below the fold, hero image eager + `fetchpriority="high"`, modern formats, meaningful `alt` (empty `alt=""` for decoration).
- Fonts: `font-display: swap`, preload the one hero font, subset if possible.
- Wrap all non-essential motion in `@media (prefers-reduced-motion: no-preference)`.
- Mobile nav: hamburger only below ~768px; keep the primary CTA visible.
- Forms: fewest fields possible, inline validation, errors say what to fix.
- `<title>`, meta description, Open Graph tags, favicon, `lang` attribute.
- No placeholder or fake content presented as real (testimonials, logos, stats). Use clearly labelled placeholders if real content is missing.

Starter tokens:
```css
:root{
  --font-sans: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --step-0: clamp(1rem, .95rem + .25vw, 1.125rem);
  --step-1: clamp(1.25rem, 1.1rem + .6vw, 1.5rem);
  --step-2: clamp(1.6rem, 1.3rem + 1.2vw, 2.25rem);
  --step-3: clamp(2.2rem, 1.6rem + 2.6vw, 3.5rem);
  --step-4: clamp(2.8rem, 1.8rem + 4.5vw, 4.5rem);
  --space-1:.25rem; --space-2:.5rem; --space-3:.75rem; --space-4:1rem;
  --space-6:1.5rem; --space-8:2rem; --space-12:3rem; --space-16:4rem; --space-24:6rem;
  --radius: 10px; --ease-out: cubic-bezier(.2,.8,.2,1); --dur: 200ms;
  --bg:#fff; --surface:#f6f7f9; --text:#111418; --muted:#5b6470; --accent:#4f46e5; --border:#e3e6ea;
}
body{font:400 var(--step-0)/1.6 var(--font-sans);color:var(--text);background:var(--bg)}
.prose{max-width:65ch}
:focus-visible{outline:3px solid var(--accent);outline-offset:2px}
@media (prefers-reduced-motion: reduce){*{animation:none!important;transition:none!important;scroll-behavior:auto!important}}
```

## 8. Avoid the generic "AI template" look
- No default purple-to-blue gradient on white with centered everything.
- Pick a real point of view from the 3 personality adjectives: a distinctive type pairing, a committed palette, one signature visual device (a shape, texture, illustration style or motion idea) used consistently.
- Vary section rhythm (full-bleed, split, grid, quote) instead of identical stacked cards.
- Write specific copy: concrete nouns and numbers beat "Unlock your potential".

## 9. QA checklist (do it, don't assume it)
Open the built page in a browser and check:
- [ ] Widths 375, 768, 1280, 1440: no horizontal scroll, no overlap, nothing cut off.
- [ ] Five-second test: from the first screen alone, can you say what it is, who it's for, what to do?
- [ ] Tab through the whole page: logical order, visible focus, every control reachable.
- [ ] Contrast of body text, muted text, buttons and text on images (compute the ratio).
- [ ] Headings outline makes sense read alone.
- [ ] Images have dimensions + alt; nothing shifts while loading.
- [ ] Reduced-motion on: page still works and nothing important is hidden.
- [ ] All links/buttons go somewhere; forms validate; no console errors.
- [ ] Lighthouse (if available): Performance, Accessibility, Best Practices, SEO ≥ 90.
Fix what fails, then re-check. Screenshot the final desktop and mobile views for the user.

## 10. Keep improving this skill
When a project teaches something new (a pattern the user liked, a mistake, a better default), propose an edit to this skill so the next site starts from it.

## Sources used
NN/g 10 Usability Heuristics; web.dev Core Web Vitals thresholds; W3C WCAG 2.2 (contrast 1.4.3, target size 2.5.8); Baymard and Bringhurst on line length; Awwwards Sites of the Year 2025; Netguru/Bubble/Line25 2026 trend reviews; live inspection of linear.app, stripe.com, apple.com, gov.uk and landonorris.com (computed styles, Nov 2026).