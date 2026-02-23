# KangaVisa Brand Guidelines v1.0

**Build partner:** Antigravity  
**Applies to:** Product UI, marketing site, onboarding, exports (Readiness Pack), GovData (DaaS) outputs

---

## 1) Executive brand summary

KangaVisa is a calm, modern Australian civic-tech product that helps people prepare decision-ready visa application packs through evidence organisation, consistency checks, and explainable risk flags—without giving legal advice or predicting outcomes.

- **Brand promise:** Clarity you can act on.  
- **Core positioning:** Readiness, not advice.  
- **Design metaphor:** A humane command centre—structured, explainable, and supportive.

---

## 2) Brand foundations

### Purpose
Reduce applicant anxiety and avoidable errors by turning messy immigration information into a structured readiness plan + exportable pack.

### Values (non-negotiable)
- **Trust-first:** transparent, no hype, no fear-selling
- **Calm under pressure:** lowers stress; clear next steps
- **Explainable:** every flag has a reason and a fix path
- **Respectful:** non-judgmental; trauma-aware language
- **Compliance-aware:** privacy/security visible and real

### Target audiences (tone implications)
- Applicants (often anxious, non-native English speakers)
- Sponsors (task-driven, evidence gathering)
- RMAs (efficiency + structure)
- Employers/HR (compliance + audit readiness)
- Government (analytics-grade outputs; methodology-first)

---

## 3) Voice, tone, and language rules

### Voice
Calm, structured, plain-English, non-judgmental.

### Writing principles (must follow)
- One idea per sentence. One action per bullet.
- Always end sections with **Next actions** (max 3–5).
- Prefer **“risk indicator” / “flag”** over any determinative language.
- Use **Assumption** blocks so users can correct the model quickly.
- Avoid idioms and slang (CALD-friendly).

### Required vocabulary discipline
Use these terms consistently:
- Readiness Pack
- Evidence Checklist
- Flags
- Timeline
- Assumptions
- Export

Avoid (unless quoting government headings verbatim):
- “guarantee”, “approve”, “certify”, “determine”, “prove”, “eligible” (as definitive outcomes)

### Microcopy examples
**Good**
- “This looks unclear. Here are three ways to strengthen it.”
- “We found a date mismatch between your CV and your reference letter.”
- “Assumption: you are applying from onshore. Change this if incorrect.”

**Bad**
- “You will be refused if you don’t…”
- “This visa will be approved.”
- “You are definitely eligible.”

### Mandatory disclaimer snippet (short, reusable)
> KangaVisa provides information and application preparation assistance. It is not legal advice and does not guarantee outcomes. For advice, consult a registered migration agent or lawyer.

**Placement rule:** Onboarding, export pack footer, and any “risk/flags” screen.

---

## 4) Visual identity and UI feel

### Personality
Modern Australian civic-tech: confident, clean, precise—never bureaucratic or “legalese”.

### UI style keywords
Card-based · Structured · Evidence-first · Calm · Explainable

### Layout rules
- 8pt spacing grid (8/16/24/32)
- Text reading width: 720–840px max on desktop
- Cards: 16–24px padding, 12–16px gaps
- Progressive disclosure: summary first, expand for detail

### Interaction rule (non-negotiable)
Every primary screen ends with a **Next Actions** block:
- Maximum 5 actions
- Each action begins with a verb
- Each action has a clear “done” state

---

## 5) Colour system (tokens + usage rules)

### Primary palette
- Deep Navy (Primary): `#0B1F3B`
- Kanga Gold (Accent): `#F4B400`
- Sky Teal (Secondary accent): `#2EC4B6`

### Semantic status colours (never used alone)
- Success: `#1FAD66`
- Warning: `#F59E0B`
- Risk/Critical: `#E11D48`
- Info: `#2563EB`

### Neutrals
- Ink: `#0F172A`
- Slate: `#334155`
- Muted: `#64748B`
- Border: `#E2E8F0`
- Surface: `#F8FAFC`
- White: `#FFFFFF`

### Colour usage rules
- Navy = navigation, headers, structural anchors
- Gold = sparingly for primary CTAs and highlights (avoid “warning gold” confusion)
- Teal = progress states and supportive cues
- Status colours must pair with:
  - icon + label text (e.g., “Risk flag”)
  - not colour-only meaning (accessibility)

---

## 6) Typography

### Type stack
- UI/Body: Inter (fallback system stack)
- Numbers/Data/IDs: JetBrains Mono (or Roboto Mono)

### Type scale
- H1 32–36 / semibold
- H2 24–28 / semibold
- H3 18–20 / semibold
- Body 14–16 / regular
- Caption 12–13 / regular

### Typography rules
- Avoid dense paragraphs; use bullets and short callouts
- Use monospace only for IDs, dates, “pack version”, and structured fields

---

## 7) Iconography and illustration

### Icon style
Rounded, line icons (Lucide-like), consistent stroke weight.

Pair semantic icons with labels:
- Flags = alert triangle
- Evidence = folder/doc
- Timeline = calendar/clock
- Export = package / arrow

### Illustration style (optional)
Minimal, abstract “navigation/map/pathway” motifs.

**Rule:** avoid cartoon kangaroos inside core workflows; reserve for marketing/onboarding if used.

---

## 8) Logo direction (brief for Antigravity/designers)

### Preferred concepts
- Abstract “K” + pathway line (most trustworthy)
- Shield + pathway (security-forward; keep modern)
- Subtle arc/tail curve as a pathway accent (tasteful only)

### Rules
- Must work in single colour (navy) for compliance docs
- Provide horizontal + icon-only variants
- Avoid crests, flags, coat-of-arms, or anything implying government affiliation

---

## 9) Component rules (developer-ready)

These components must exist and follow the content structure rules.

### 9.1 Readiness Scorecard (must not imply probability)
**Purpose:** show completeness and progress, not approval likelihood.

Must include:
- Evidence coverage %
- Unresolved flags count
- Timeline gaps count
- “Last updated” timestamp

Must not include:
- “chance of approval”, “probability”, “approval likelihood”

### 9.2 Flag Cards (required structure)
Every flag card must show:
- Trigger (what was detected)
- Why it matters (plain language)
- Actions (step-by-step, max 3–5)
- Evidence examples (what good looks like)
- Status (Unresolved / Resolved by note / Resolved by evidence)

### 9.3 Evidence Checklist (table/grid)
- Evidence Items × status (N/A / In progress / Done)
- Each item has “What it proves” expandable
- Each item supports mapping documents to evidence

### 9.4 Timeline View
- Shows gaps, overlaps, and conflicts clearly
- “Add event” and “Explain gap” actions built-in
- Always links issues back to flags

### 9.5 Export Pack Summary
The export screen must show:
- Case snapshot (goal, onshore/offshore, intended pathway)
- Evidence coverage %
- Top unresolved flags (max 5)
- Assumptions
- Export date + pack version

---

## 10) Trust & compliance cues (UX requirements)

### Trust cues to build into UI
- “Why we ask this” on sensitive questions
- Consent controls:
  - Product analytics (basic)
  - De-identified research / GovData (separate)
- Security cues in settings (plain-English):
  - encryption
  - access controls
  - audit logs

### Dark patterns banned
- Fear-based upsells
- Fake urgency (“only 2 hours left”)
- “Approval likelihood” meters
- Any copy that implies government partnership unless true and explicit

---

## 11) Accessibility (brand-level requirements)

Target WCAG 2.1 AA:
- Contrast ≥ 4.5:1 for body text
- Keyboard navigation for all workflows
- Error states must include text + icon + fix guidance
- Avoid idioms; keep language simple (CALD-friendly)

---

## 12) GovData (DaaS) sub-brand guidelines

GovData outputs must look analyst-grade and “methodology-first”.

### Visual rules
- Same palette, but reduce gold usage
- More tables, whitespace, and footnotes
- Charts: simple, clean, labeled axes, clear time windows

### Content rules (required in every report/dashboard)
- Data dictionary / definitions
- Time window + cohort filters
- Suppression threshold note
- Methodology summary
- Limitations / caveats

**Non-negotiable:** no individual-level outputs; no personal profiling.

---

## 13) Messaging blocks (copy ready)

### One-liner
KangaVisa helps you prepare a decision-ready visa application pack—clear, structured, and explainable.

### Value pillars (UI + marketing)
- Know your pathway
- Build your evidence
- Fix the gaps
- Export with confidence

### Trust line
“KangaVisa is an information and preparation tool. It is not legal advice and does not guarantee outcomes.”

---

## 14) Deliverables Antigravity should produce (definition of “brand implemented”)

- Design tokens (colours, spacing, radii, typography)
- Component library (Scorecard, Flag Card, Checklist, Timeline, Export Summary)
- Marketing kit (hero, pillars, trust section, FAQ, pricing)
- Readiness Pack PDF template (versioned, compliant)
- GovData report template (dashboard + methodology appendix)

---

## Optional next artefacts (if you want)
- Design token JSON (ready for Tailwind / CSS variables)
- Screen-by-screen UI style guide (required components + allowed copy patterns per screen)
