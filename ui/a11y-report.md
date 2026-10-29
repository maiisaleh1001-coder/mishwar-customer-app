# «مشوار» customer app: WCAG 2.2 AA accessibility audit

**Scope:** 92 `*.dc.html` files in `design-canvas/project/`: 88 screens and 4 shared components (`Bottom-Nav`, `Map-Route`, `Provider-Card`, `Main`). Also reviewed: `ui/UI-GUIDELINES.md` and `ui/assets/map/riyadh-olaya.svg`.
**Mode:** Read-only. No design file was changed.
**Date:** 2026-10-28.

## How the audit was done

- **Static markup scan.** A tag-stack parser walked every element inside `<x-dc>`. For each text node it worked out the color, font-size and weight the node inherits from inline styles, plus the nearest solid ancestor background. `rgba()` and `opacity` were blended over that background. This produced 1,237 text nodes and 3,793 elements.
- **Contrast.** Ratios use the WCAG 2.x relative-luminance formula. Every ratio in this report was computed, not estimated.
- **Element inventories.** Separate lists were built for buttons (411), inputs (26), SVGs (376), roles and ARIA attributes, headings, and `dir="ltr"` usage. These were followed by a manual read of about 35 representative screens.
- **Imports.** A `<dc-import>` component is audited once in its own file. Findings in `Map-Route`, `Provider-Card` and `Bottom-Nav` therefore apply to every screen that imports them.
- **Limitations.**
  - The files are static mocks, so focus order, live announcements and real screen-reader output could not be observed. Those findings are about what the spec must state.
  - Inline styles cannot express `:focus-visible` or `::placeholder`. Their absence is reported as a spec gap, not proven to be a bug in the built app.

## Executive summary

The markup is better than most design mocks:

- Every icon-only button has an `aria-label` (0 missing out of 411 buttons).
- All 376 SVGs are either `aria-hidden` or `role="img"` with a label.
- Every `<img>` has `alt=""` and is decorative.
- Radio groups, tabs and accordions carry `aria-checked`, `aria-selected` and `aria-expanded`.
- LTR runs are wrapped in `dir="ltr"` almost everywhere: phone numbers, plates, card numbers, order IDs, file names.
- The body color `#5B6766` passes on every surface it is used on (5.23–5.87:1).

The failures are **systemic and token-level**. Fixing about 6 tokens or specs in `UI-GUIDELINES.md` clears most of them:

1. **`mute #8E9897` is used as real text and as the placeholder color, and it fails everywhere** (2.65–2.96:1).
2. **The success green `#2E8B3E` fails as text** on its own `success-50` pill (3.85:1).
3. **Text links and chips are below the 44 px app target.** About 20 text links are only 20–22 px tall, which fails WCAG 2.5.8.
4. **No focus-visible style is specified** for any control except text fields.
5. **No live regions.** Ride, upload and chat status changes are never announced.
6. **Several controls are drawn as `<span>`:** fields, a switch, and the Terms and Privacy links. Built as drawn, they cannot be used with a keyboard or screen reader.
7. **Non-text contrast fails** for rating stars, radio rings and the timeline.

| Priority | Findings | Approx. instances |
|---|---|---|
| Critical | 1 | 33 text nodes in 13 screens, plus every placeholder |
| High | 8 | about 130 |
| Medium | 10 | about 250 (dominated by 40 px back buttons and 12 px secondary text) |
| Low | 7 | about 40 |

---

## Priority index

| ID | Priority | WCAG | Finding | Count | Fix (one line) |
|---|---|---|---|---|---|
| C-1 | **Critical** | 1.4.3 | `mute #8E9897` used for text and placeholders: 2.65:1 on field, 2.77:1 on card, 2.96:1 on white | 33 nodes / 13 screens, plus all placeholders | `mute` → **`#646E6D`** (4.70 on #F2F2F2, 4.92 on #F5F8F8, 5.26 on #FFF), or use `body #5B6766` |
| H-1 | High | 1.4.3 | Success green `#2E8B3E` text 3.85:1 on `#EAF5EC` and 4.30:1 on white; warning `#B7791F` text 3.41:1 | 9 nodes / 6 screens | Text-only token `success-text` **`#237033`** (5.46 / 6.11); warning text → `#8A5A12` (5.54) |
| H-2 | High | 2.5.8 | Inline text links and accordion headers with `padding:0` are about 20–22 px tall | 21 links / 16 screens, plus 6 FAQ rows | Min hit area 44 px: `min-height:44px; padding:12px 8px` or a `::before` hit-slop |
| H-3 | High | 2.4.7 / 2.4.11 | No focus indicator specified for buttons, chips, cards or list rows. Fields use `outline:none` | All 411 buttons | Add a `focus-visible` token: 2 px `#0F6E6E` ring, 2 px offset (white ring on teal or red buttons) |
| H-4 | High | 4.1.3 | No `aria-live` or `role="status"` anywhere except the OTP error | Ride (8), searching (2), upload, chat, stepper, toasts | Add `role="status"` to live status lines. Add `role="log"` to chat |
| H-5 | High | 4.1.2 / 2.1.1 | Controls drawn as non-interactive `<span>`: fake fields, switch, Terms and Privacy links, notification rows | 8 fake fields, 1 switch, 2 links, 9 rows | Implement as `<input>`, `<textarea>`, `<select>`, `<a>`, `<button>`, `<button role="switch">` |
| H-6 | High | 3.3.8 / 1.3.5 / 3.3.1 | OTP: no `autocomplete="one-time-code"`, no paste spec, no group label; error not linked to inputs | C05, C05e | `autocomplete="one-time-code"`, paste fills all 4, `role="group"`, `aria-describedby` → error |
| H-7 | High | 1.4.11 | Rating stars: empty `#CFE6E4` is 1.30:1, filled `#E2A23B` is 2.22:1. Radio rings `#8E9897` are 2.96:1 | C140 (5 stars), radios in C100 and C121 (7) | Empty star stroke `#6B7675` (4.69). Filled star gets a `#9A6A14` stroke (4.72). Radio ring → `#646E6D` |
| H-8 | High | 2.5.8 (app 44) | Emergency and destructive mini targets: **SOS** 40 px tall; «احذف الصورة» 24×24 overlapping a thumbnail | SOS ×4; delete ×1 | SOS 48 px tall. Delete-image button 44×44 hit area |
| M-1 | Medium | 2.5.8 (app 44) | 40×40 back buttons, 36–40 px icon buttons, chips and tabs | 54 back, 12 icon, ~60 chips/tabs | Back and icon buttons 44×44. Chips `min-height:44px` (visual 36–40 allowed with hit-slop) |
| M-2 | Medium | 1.3.1 / 2.4.6 | 20 screens have **no heading**. 4 home screens start at `h2`. Section labels are `<span>` | 24 screens | Top-bar title → `<h1>`. Home gets an h1. Section labels → `<h2>` |
| M-3 | Medium | 1.4.4 (best practice) | 11 px text; 12–13 px used for step labels, ride stepper, status pills and invoice prices | 14 nodes at 11 px; 12–13 px in ~60 screens | Min 12 px for meta. 14 px for status, step labels and prices |
| M-4 | Medium | 1.4.1 / 1.3.1 | Information conveyed only by color, position or shape: chat sender, upload done, unread dot, from/to markers | C110, C84, C150, C130/C30a | Add visually-hidden text or a visible label |
| M-5 | Medium | 4.1.2 / 2.4.3 | Bottom sheets lack `aria-modal="true"`, inert background and focus management | 10 dialogs | `aria-modal="true"`, `inert` on the underlying screen, focus to sheet title, restore on close |
| M-6 | Medium | 1.3.5 / 3.3.2 | No `autocomplete` on any field. C21 fields have no visible label | 26 inputs | `autocomplete="tel-national"`, `name`, `email`. Visible «من» / «إلى» labels in C21 |
| M-7 | Medium | 1.4.11 | Low-contrast boundaries and state graphics: fields `#F2F2F2` 1.12, chip border `#E4E9E8` 1.23, dashed `#CFE6E4` 1.30, timeline upcoming 1.30, current sand 2.22 | ~100 | Unselected chip and field border `#7D8786` (3.70). Timeline upcoming `#7D8786`. Current node gets a `#9A6A14` ring |
| M-8 | Medium | 2.5.7 | C164 «حرّك الخريطة» sets the address only by dragging the map. No search or tap alternative | C164 | Add a search field (as in C11) or tap-to-place |
| M-9 | Medium | 1.4.4 / 1.4.10 / 1.4.12 | `white-space:nowrap` plus fixed heights on pills, chips and the C02a h1 clip text at 200% font scale | ~70 | `min-height` instead of `height`; allow wrap; test at 200% Dynamic Type |
| M-10 | Medium | 4.1.2 / 3.3.1 | C84: determinate progressbar has no `aria-valuenow`; file-size error is not announced | C84 | `aria-valuenow="60" aria-valuemin="0" aria-valuemax="100"`; error `role="alert"` |
| L-1 | Low | 1.3.2 / 3.1.2 | RTL: arrows are hard-coded and will be wrong in English. The «←» glyph is read aloud. Missing `lang="en"` on English text | 55 back arrows, 5 glyphs, 2 English runs | Mirror directional icons under `[dir=ltr]`. Glyph `aria-hidden`. Add `lang="en"` |
| L-2 | Low | 1.4.3 (image of text) | Map SVG: minor street labels 9.5 px `#7A8684` (3.38–3.77); landmarks 11 px `#6B7876` (4.12) | 6 labels | All labels `#4F5D5B` (6.18) at 11 px or larger |
| L-3 | Low | 1.4.3 | Splash 12 px `rgba(255,255,255,.6)` on teal is 3.24. The X02 illustration uses 11 px text at 0.85 opacity (4.19) | C01, X02 | Use `#CFE6E4` (4.63) or `rgba(255,255,255,.85)` (4.85). Mark the illustration `aria-hidden` |
| L-4 | Low | 1.4.11 | Row chevrons `#8E9897` (2.77–2.96) | C160, C131, C132 and others (~25) | `#646E6D` |
| L-5 | Low | 1.3.1 | No list semantics for repeated items. Very long names on card-buttons. `+966` not tied to its input. «••••» read literally | many | `<ul>/<li>`; concise `aria-label` on card buttons; `aria-describedby` for the prefix |
| L-6 | Low | 2.3.3 / 2.2.1 | Motion (OTP shake, search pulse, spinner) and countdowns are not specced for reduced motion or announcements | C05e, C24, C45, C84, C05, C05l | Respect `prefers-reduced-motion`. Announce only when a countdown ends |
| L-7 | Low | 4.1.2 | C85 closed days use native `disabled` on `role="radio"`, which removes them from the reading order | 2 | Use `aria-disabled="true"` and keep them focusable |

---

## 1. Text contrast (SC 1.4.3)

### 1.1 Every text-color / background pair used

Computed with the WCAG formula. "Sizes" are the font-size/weight values seen with that pair. Pairs whose effective (blended) colour has no hex in the files are marked as blended.

| Text | Background | Ratio | Uses | Sizes seen | Verdict |
|---|---|---|---|---|---|
| `#8E9897` mute | `#F2F2F2` field | **2.65** | 4 | 14, 15 | **Fail** |
| `#8E9897` mute | `#F5F8F8` card | **2.77** | 8 | 11, 12, 13, 18b | **Fail** (C85 disabled days exempt) |
| `#8E9897` mute | `#FFFFFF` | **2.96** | 25 | 11–14 | **Fail** |
| `#9FC5C5` (blended white @ .6) | `#0F6E6E` | **3.24** | 1 | 12 | **Fail** (C01) |
| `#B7791F` warning | `#F5F8F8` | **3.41** | 1 | 14/500 | **Fail** (C175) |
| `#2E8B3E` success | `#EAF5EC` | **3.85** | 5 | 12/500, 14/500 | **Fail** |
| `#747E7D` (blended, opacity .85) | `#FFFFFF` | **4.19** | 1 | 11 | **Fail** (X02 illustration) |
| `#2E8B3E` success | `#FFFFFF` | **4.30** | 4 | 12/500, 14/500 | **Fail** |
| `#CFE2E2` (blended white @ .8) | `#0F6E6E` | 4.50 | 1 | 16 | Pass (exactly at the limit) |
| `#CFE6E4` | `#0F6E6E` | 4.63 | 6 | 11, 12 | Pass |
| `#FFFFFF` | `#2F6FDE` (VISA tile) | 4.72 | 2 | 11/700 | Pass (logotype) |
| `#C53030` error | `#FCEDED` | 4.81 | 1 | 12/500 | Pass |
| `#5B6766` body | `#E9F4F3` | 5.23 | 36 | 12–17 | Pass |
| `#5B6766` | `#F2F2F2` | 5.24 | 2 | 12 | Pass |
| `#5B6766` | `#EAF5EC` | 5.25 | 3 | 12, 14 | Pass |
| `#5B6766` | `#FBF3E4` | 5.32 | 5 | 12, 14 | Pass |
| `#8A5A12` | `#FBF3E4` | 5.36 | 1 | 14/500 | Pass |
| `#5B6766` | `#F4F5F5` home-bg | 5.38 | 4 | 14/500 | Pass |
| `#0F6E6E` primary | `#E9F4F3` | 5.38 | 4 | 12–16 | Pass |
| `#0F6E6E` | `#F2F2F2` | 5.40 | 1 | 13/500 | Pass |
| `#5B6766` | `#FCF5E8` sand-50 | 5.41 | 8 | 12, 14 | Pass |
| `#8A5A12` | `#FCF5E8` | 5.45 | 3 | 12/500 | Pass |
| `#FFFFFF` | `#C53030` | 5.47 | 6 | 14/700, 16/500 | Pass |
| `#C53030` | `#FFFFFF` | 5.47 | 10 | 12–16 | Pass |
| `#5B6766` | `#F5F8F8` | 5.50 | 48 | 12–16 | Pass |
| `#0F6E6E` | `#F4F5F5` | 5.53 | 2 | 14/500 | Pass |
| `#0F6E6E` | `#F5F8F8` | 5.66 | 5 | 13, 14 | Pass |
| `#5B6766` | `#FCFCFC` (OSM chip) | 5.72–5.74 | 4 | **9** | Pass on contrast, see size |
| `#5B6766` | `#FFFFFF` | 5.87 | 312 | 12–16 | Pass |
| `#FFFFFF` | `#0F6E6E` | 6.04 | 81 | 13–36 | Pass |
| `#0F6E6E` | `#FFFFFF` | 6.04 | 24 | 11–16 | Pass |
| `#7A5410` | `#FBF3E4` | 6.14 | 6 | 12–14 | Pass |
| `#7A5410` | `#FCF5E8` | 6.24 | 9 | 12–22 | Pass |
| `#1B2B2B` ink | `#E2A23B` sand | 6.63 | 6 | 11, 12 | Pass |
| `#7A5410` | `#FFFFFF` | 6.77 | 1 | 16/500 | Pass |
| `#0B5555` | `#E9F4F3` / `#FBF3E4` / `#F4F5F5` / `#FFFFFF` | 7.65–8.59 | 22 | 12–16 | Pass |
| `#1B2B2B` ink | all light surfaces | 13.1–14.7 | 590 | all | Pass |
| `#FFFFFF` | `#1B2B2B` (toast, tiles) | 14.72 | 3 | 11, 12 | Pass |

Answers to the pairs named in the brief:

- `#5B6766` on white, `#F2F2F2`, `#F4F5F5`, `#E9F4F3` and `#FCF5E8`: **all pass**.
- `#8A5A12` on `#FCF5E8` passes at 5.45.
- White on `#0F6E6E` passes at 6.04.
- `#C53030` passes on white (5.47) and on `#FCEDED` (4.81).
- Status pills:
  - **Green «مدفوع» fails.**
  - Sand-50 pills with `#7A5410` pass at 6.24.
  - «ملغي» `#C53030` on `#FCEDED` passes at 4.81.
- Placeholder `#8E9897` **fails**.

### C-1 (Critical): `mute #8E9897` used as real text and placeholder

`UI-GUIDELINES.md` §2 says mute is for «الـ placeholders بس». §8 then prescribes it for list-group labels («Label فوقه 12/500 `mute`»), row values («قيمة 13 `mute`») and notification times («الوقت 12 `mute`»). Placeholder text is **not** exempt from 1.4.3. **33 text nodes in 13 screens** fail.

Examples:

- `C165-Delete-Account.dc.html:31`, fake select placeholder, 15 px, **2.65:1**:
  `<span style="…background: #F2F2F2…font-size: 15px; color: #8E9897">اختر السبب`
- `C150-Notifications.dc.html:21` and `:24`, section header «اليوم» 12/500 and timestamp «من دقيقتين», **2.96:1**.
- `C160-Profile.dc.html:21`, `:24` and `:37`, group labels «الحساب» and row values «3» and «العربية» on `#F5F8F8`, **2.77:1**.
- `C161-Edit-Profile.dc.html:31` and `:43`, field help text, for example «الرقم هو طريقة دخولك…», 12 px, **2.96:1**.
- `C110-Chat.dc.html:22` and `:26`, message timestamps, 11 px, **2.77 / 2.96**.
- `C134-Invoice.dc.html:46`, ZATCA compliance note, 11 px, **2.96**.
- Also affected: `C140:38` and `:39`, `C163:36`, `C164:40` and `:41`, `C168:29`, `C171:27`, `C173:21`, `C174:42`.
- **Real `placeholder=""` attributes** (C03, C07, C11, C21, C42, C80, C110) have no colour specified. No `::placeholder` rule exists anywhere, so the platform default is used. iOS and Android defaults are about 3–4:1 on `#F2F2F2`.

**Fix:**

- Change the `mute` token from `#8E9897` to **`#646E6D`**. It gives 4.70 on `#F2F2F2`, 4.92 on `#F5F8F8`, 4.68 on `#E9F4F3`, 4.85 on `#FCF5E8` and 5.26 on white.
- Also apply `::placeholder { color: #646E6D }` (Android `textColorHint`, iOS `attributedPlaceholder`).
- Alternative: drop `mute` for text and use `body #5B6766` (5.24 on `#F2F2F2`). Keep `#8E9897` only for disabled text, which is exempt, and decorative lines.

### H-1 (High): success-green and warning text

- `#2E8B3E` on `#EAF5EC` = **3.85**:
  - `C07-Complete-Profile.dc.html:19` «تأكدنا من رقمك», 14/500.
  - `C130-Orders.dc.html:31` and `:39` «مدفوع», 12/500.
  - `C131-Order-Details.dc.html:23` «مكتملة ومدفوعة».
- `#2E8B3E` on white = **4.30**:
  - `C124-Payments-History.dc.html:30`, `:35` and `:40` «مدفوع», 12/500.
  - `C86-Gov-Summary.dc.html:30` «5 من 5 جاهزة».
- `#B7791F` on `#F5F8F8` = **3.41**: `C175-Contact-Sent.dc.html:22`, `<span style="color: #B7791F; font-weight: 500">قيد المراجعة`.

**Fix:**

- Add a `success-text` token **`#237033`** (5.46 on `#EAF5EC`, 6.11 on white). Keep `#2E8B3E` for icons, where 4.30 ≥ 3:1 is fine.
- Warning text → **`#8A5A12`** (5.54 on `#F5F8F8`) or `#7A5410`, which is already used for sand pills.
- Add to §2: «`warning` و`success` للأيقونات والإطارات بس، والنص بدرجته الغامقة».

### L-3 (Low): splash and illustration

- `C01-Splash.dc.html:20`, `color: rgba(255,255,255,0.6)`, 12 px → **3.24**.
  Fix: `#CFE6E4` (4.63) or `rgba(255,255,255,.85)` (4.85).
- Line 18 at `.8` is exactly 4.50. Raise it to `.85` for margin.
- `X02-Notifications-Permission.dc.html:22–24`: mock notification at `opacity:.85` with 11 px text (4.19). It is an illustration, so put `aria-hidden="true"` on its container and exempt it. Otherwise remove the opacity.

---

## 2. Non-text contrast (SC 1.4.11)

| Element | Colours | Ratio | Where (count) | Verdict / fix |
|---|---|---|---|---|
| Rating star, empty | stroke `#CFE6E4` on white | **1.30** | `C140-Rating.dc.html:24–25` | **Fail.** Stroke `#6B7675` (4.69) or `#0F6E6E` (6.04) |
| Rating star, filled | fill `#E2A23B` on white | **2.22** | `C140:21–23` | **Fail.** Keep sand fill, add stroke `#9A6A14` (4.72) |
| Radio ring, unselected | 2 px `#8E9897` on white / `#F5F8F8` | **2.96 / 2.77** | `C100-Cancel-Reason.dc.html:25–28`, `C121-Payment-Methods.dc.html:24,34,39` (7) | **Fail.** Ring `#646E6D` (5.26) |
| Text field, unfocused | fill `#F2F2F2` on white, no border | 1.12 | every form (C07, C42, C61, C21, C11, C80) | Borderline. The label identifies the field, but low-vision users lose the target. Add a 1 px `#7D8786` border (3.70) or a bottom rule |
| Selection chip, unselected | 1 px `#E4E9E8` on white | 1.23 | 67 + 10 instances (C100, C140, C164, C40, C42, C174, C61…) | Boundary invisible. Selected state is fine (2 px `#0F6E6E`, 6.04). Use `#7D8786` (3.70 on white, 3.29 on `#E9F4F3`) |
| Quick-reply chips (chat) | 1 px `#CFE6E4` on white | 1.30 | `C110-Chat.dc.html:31–33` | Same fix |
| Dashed "add" tiles | `#CFE6E4` dashed | 1.30 | C121:41, C40:32, C84:54, C174:46, C61:29 (7) | `#7D8786` dashed |
| Order timeline, upcoming node and connector | 1.5 px `#CFE6E4` on white | **1.30** | Main:47–50, C10d, C30a:30–35, C30b, C30c, C70a, C90a:28–30 | Supplementary: a text alternative exists (`role="img" aria-label="المرحلة…"`, plus visible pill). Still raise to `#7D8786` |
| Order timeline, current node | `#E2A23B` on white | 2.22 | same | Add a 2 px `#9A6A14` ring, or rely on the larger size plus text (already present) |
| Step progress bars, to-do segments | `#E9F4F3` on white | 1.12 | C40:22 and 11 other step screens | OK: «الخطوة 1 من 3» text exists. Optional `#7D8786` |
| Progressbar track | `#E9F4F3` with `#0F6E6E` fill | fill 6.04 | C24:24, C45, C84:42 | Pass |
| Selected border | 2 px `#0F6E6E` on `#E9F4F3` / white | 5.38 / 6.04 | 21 | Pass |
| Error border | 2 px `#C53030` on white | 5.47 | C05e (4), C84:44 | Pass |
| Status icons | `#2E8B3E` 4.30, `#B7791F` 3.30 on `#FBF3E4`, `#C53030` 5.47 | ≥ 3 | many | Pass |
| Row chevrons | `#8E9897` on `#F5F8F8` / white | 2.77 / 2.96 | C160 (all rows), C131:49–51, C132:41, C21, C173 | L-4: `#646E6D` |
| Focus states | inputs: 2 px `#0F6E6E` (6.04) | n/a | fields only | **Buttons: none specified** (H-3) |
| Toggle | on: `#0F6E6E` track with white knob | 6.04 | C160:38 | Off state not designed. Specify an off track ≥ 3:1 (e.g. `#7D8786` with white knob) |

### H-3 (High): focus indicator not specified

- Inputs use `outline: none` and substitute a 2 px `#0F6E6E` border. This is acceptable, and it is designed (C03:25, C05:27, C21:29).
- **No button, chip, tab, card or list row has any focus treatment.** §8 only defines focus for Text field and OTP («من غير هالة أو ظل»).
- External-keyboard, switch-access and TalkBack/VoiceOver focus users get no visible indicator on about 400 buttons.
- Floating elements can cover the focused item. 2.4.11 (Focus Not Obscured) applies:
  - Bottom-Nav floats at `bottom:40px`.
  - Bottom sheets cover the lower 40–60% of map screens.

**Fix:** add a token to §4:

```
focus-ring: 2px solid #0F6E6E; outline-offset: 2px
on teal/red fills: 2px solid #FFFFFF, plus an outer 2px #1B2B2B
```

In the built app, use `scroll-padding-bottom` ≥ nav height plus 16. In native code, use the platform focus highlight. Do not suppress it.

---

## 3. Text size

### < 12 px (14 text nodes, excluding logos)

| Size | Where | Text | Note |
|---|---|---|---|
| 9 px | `Map-Route.dc.html:27`, `C11:17`, `C11p:18`, `C164:19` | «© OpenStreetMap» | Legal attribution. Contrast passes (5.7). Raise to 11 px |
| 11 px | `C110-Chat.dc.html:22,23,26,28` | message timestamps (also fail contrast at 2.77–2.96) | 12 px `#646E6D` |
| 11 px | `C134-Invoice.dc.html:46` | ZATCA compliance line (also 2.96) | 12 px `body` |
| 11 px | `C174-Contact.dc.html:46` | «صورة» label on the upload button | 12–13 px |
| 11 px | `Main:22`, `C10d:22`, `C10e:22`, `C123:22`, `C124:22` | badge counts «3», «2» | OK for a badge digit, but the count is only in the aria-label on Main. Fine |
| 11 px | `X02:24` | illustration | Hide from AT |
| 9–11 px | `C120:35`, `C121:27,32,37`, `C167:29,39` | «مدى», «VISA», «stc pay» tiles | Logotypes, exempt |

### 12–13 px used for important information (M-3)

There are 343 text nodes at 12–13 px. Most are secondary meta text (dates, order IDs, addresses), which is acceptable at 12 px with passing contrast. These carry primary information and should be 14 px:

- **Step labels** «الخطوة N من M · …» at 12 px in 12 screens: `C40:23`, `C42:23`, `C44:23`, `C61:23`, `C63:23`, `C65:23`, `C80:23`, `C81:23`, `C82:23`, `C84:23`, `C85:23`, `C86:23`.
- **Live ride stepper labels** «في الطريق / وصل / الرحلة جارية / انتهت» at 12 px: `C30a-Ride-On-The-Way.dc.html:37`, C30b, C30c, C70a.
- **Status pills** at 12/500:
  - «مدفوع»: C124 ×3, C130 ×2.
  - «غير مدفوع»: C130:47.
  - «مكتملة ومدفوعة»: C131:23.
  - «ملغي»: C132:23.
  - «جاري التنفيذ»: C90a:23.
  - «السائق في الطريق» / «مع المندوب»: Main:41, :62 and C10d.
- **Prices:**
  - **Entire invoice at 13 px**, including all line items and VAT: `C134-Invoice.dc.html:35–42` («15.65 ر.س», «2.48 ر.س»).
  - Debt pill «10.00 ر.س» 12 px: `C160:31`.
  - «رسوم إلغاء · 10.00 ر.س» 13 px: `C166:31`.
- **Plate number** at 12 px in order details: `C131:30`. Provider-Card uses 13/700.
- Small inline actions at 13 px: «تغيير» (C174:36), «تعديل» (C169:25,36), «تابعها», «ادفع» (C166:27,32), «اجعله الأساسي» (C167:31).

**Fix:**

- In §3, set a floor: `caption` 12 px for meta only.
- Status pills, step labels, prices and actions use `body-sm` 14 px.
- Invoice body 14 px, total 16/700.

---

## 4. Touch targets (WCAG 2.5.8 minimum 24×24; app target 44×44)

| Pattern | Size | Count | Examples | 2.5.8 | App 44 | Fix |
|---|---|---|---|---|---|---|
| **Inline text links, `padding:0`** | about 20–22 px tall (14 px font, normal line-height) | **21** | «تعديل الرقم» `C05:22`, `C05e:22`; «تغيير» `C161:29`, `C174:36`; «تعديل» `C169:25,36`; «ادفع» `C10d:29`, `C166:32`; «تابعها» `C166:27`; «تخطي» `C140:16`; «عرض الكل» `Main:34`, `C10d:40`; «تواصل مع الدعم» `C30c:41`, `C50b:43`, `C90a:45`; «اجعله الأساسي» `C167:31`; «الأشياء الممنوع توصيلها» `C42:61`; «تعليم الكل كمقروء» `C150:18` | **Likely fail** where neighbours are under 24 px away (e.g. C167:31 next to the delete button) | Fail | **H-2:** `min-height:44px; padding:12px 8px; margin:-12px -8px` (hit-slop without changing layout) |
| FAQ accordion headers | button 22 px tall inside a 50 px row (padding is on the parent `div`) | 6 | `C173-FAQ.dc.html:31,34–38` | Passes by spacing | Fail | Move `padding:14px 0` onto the `<button>` |
| Payment row «مدى •••• 4821 تغيير» | `padding:4px 0` → about 28 px | 1 | `C22-Ride-Category.dc.html:37` | Pass | Fail | `padding:12px 0` |
| **SOS (emergency)** | height 40 | 4 | `C30a:19`, `C30b:19`, `C30c:18`, `C70b:19` | Pass | Fail | **H-8:** 48 px tall |
| **Delete image** | **24×24**, positioned at −6 px over the thumbnail | 1 | `C174-Contact.dc.html:45` | Exactly at the minimum | Fail | **H-8:** 44×44 hit area (visual 24 is OK) |
| Back button | 40×40 | **54** | every top bar, e.g. `C03:16`, `C05:16`, `C120:16`; floating: `C30a:16`, `C11:24` | Pass | Fail | 44×44 (C164:20 already uses 44). Update §5: «دايرة 44» |
| Icon buttons, 40 | 40×40 | 6 | bell `Main:20`, `C10d:20`, `C10e:20`; call `C110:18`; my-location `C11:25`; share `C70b:18` | Pass | Fail | 44×44 |
| Icon buttons, 36 | 36×36 | 6 | delete file `C84:30,35`; address options `C163:24,29,34`; delete card `C167:32` | Pass | Fail | 44×44, especially destructive actions |
| Chips / tabs, 36 | height 36 | 15 | `C140:31–35`, `C173:23–27` (role=tab), `C110:31–33`, `C160:18` «تعديل», `C02a:17` «English» | Pass | Fail | `min-height:44px`, or 36 visual with 4 px invisible hit-slop |
| Chips / tabs / pills, 40 | height 40 | about 45 | service tabs `C130:18–21`, `C130e`; `C123:22–23`, `C124`; chips `C42:45–55`, `C164:33–35`, `C40:41–43`, `C60:25–27`, `C61:27–29`, `C174:25–29`; `C84:50–58`; «مشاركة» `C30a:18`; «دخول» `C10g:20` | Pass | Fail | 44 |
| Toggle | 44×26, on a **non-focusable `<span role="switch">`** | 1 | `C160-Profile.dc.html:38` | n/a | n/a | Make the whole 46 px row a `<button role="switch">` (see H-5) |
| Rating stars | 48×48 | 5 | C140:21–25 | Pass | Pass | none |
| OTP boxes | 64×64 | 8 | C05, C05e | Pass | Pass | none |
| Bottom-Nav | 52×52 | 3 | Bottom-Nav | Pass | Pass | none |
| Primary / secondary buttons | 56 / 44 | many | n/a | Pass | Pass | none |

---

## 5. Names, roles and semantics

### What is already correct

- **0 of 411** buttons lack an accessible name. Icon-only buttons all have `aria-label` («رجوع», «إرسال», «احذف البطاقة», «الإشعارات، 3 جديدة», «طوارئ SOS»…).
- **All 376 SVGs** are `aria-hidden="true"` or `role="img"` + `aria-label` (flag «السعودية», QR «رمز QR للفاتورة», timer «مضى ساعة و35 دقيقة من 4 ساعات»). The one exception, `C02a:24`, sits inside an `aria-hidden` container, so it is fine.
- **All 27 `<img>`** have `alt=""`. They are 3D service icons and the map background, which is correct because a text label sits next to each.
- **Radio groups** (17 groups / 70 radios) use `role="radiogroup"` + `aria-label` and `role="radio"` + `aria-checked`. **Tabs** (9 tablists) use `aria-selected`. **Accordion** uses `aria-expanded`. **Rating** chips use `aria-pressed`. **Nav** uses `<nav aria-label>` + `aria-current="page"`.
- All 26 real `<input>` elements have a `<label for>` or `aria-label`.
- OTP error uses `aria-invalid="true"` + `role="alert"` (`C05e:25–30`).

### H-5 (High): controls drawn as non-interactive elements

If built as drawn, these cannot be reached by keyboard or announced correctly.

| What | Where | Problem | Fix |
|---|---|---|---|
| Fake text fields / select / textarea | `C140:39` comment, `C161:35` email, `C162:23–24` phone, `C164:37,41` address name and details, `C165:31` «اختر السبب» select, `C173:21` FAQ search, `C174:41` message textarea (8) | `<span>` styled as a field. Not focusable, no role, no value | Real `<input>`, `<textarea>`, `<select>` (or a `button` + listbox for the select) with the existing `<label>` |
| Toggle | `C160-Profile.dc.html:38`: `<span role="switch" aria-checked="true" aria-label="إشعارات العروض">` | Has a role but no `tabindex` or keyboard handler | `<button type="button" role="switch" aria-checked>` spanning the whole row |
| Terms / Privacy "links" | `C07-Complete-Profile.dc.html:30`: `<span style="color:#0F6E6E;text-decoration:underline">الشروط والأحكام</span>` inside the checkbox `<label>` | Not links. Tapping toggles the checkbox, so the documents cannot be opened | `<a href>` placed **outside** the `<label>`, or as separate buttons |
| Notification rows | `C150-Notifications.dc.html:22,27,32…` (`<div>`) | Rows look tappable (they lead to the order) but are not buttons or links | `<a>` or `<button>` per row |
| Unread dot | `C150:25,30`: `<span aria-label="غير مقروء" …>` | `aria-label` on a generic `<span>` is ignored by AT | Visually-hidden text «غير مقروء», or `role="img"` |

### M-2 (Medium): headings

- **20 screens have no heading at all.** The top-bar title is a `<span style="font-size:16px;font-weight:500">`. Example: `C120-Payment-Summary.dc.html:17` `<span …>الدفع</span>`.
  Affected: C110, C111, C120, C123, C124, C131, C132, C134, C150, C160, C161, C163, C167, C168, C169, C173, C174, C21, C66, C86.
- **Home screens** (Main, C10d, C10e, C10g) start at `<h2>` («طلباتك الجارية», «الخدمات») with no `<h1>`.
- **Section labels are spans:** C160 «الحساب / المدفوعات / التطبيق» (`:21,29,35`), C150 «اليوم / سابقاً» (`:21,36`), C171 uses `h2` correctly.
- **Fix:**
  - Top-bar title → `<h1>`. iOS: `.accessibilityAddTraits(.isHeader)`. Android: `heading()`.
  - Home → add `<h1>` (e.g. «أهلاً، محمد», or visually hidden «الرئيسية»).
  - Section labels → `<h2>`.

### M-4 (Medium): information by colour, position or shape only

- **Chat** (`C110-Chat.dc.html:22–28`): sender is shown only by bubble side and colour (grey left = driver, teal right = me). Fix: visually-hidden prefix «السائق:» / «أنت:» per message, and `role="log"` on the list.
- **Uploaded files** (`C84-Gov-Upload.dc.html:27–35`): «done» is shown by the green `#EAF5EC` background and an `aria-hidden` green tick only. There is no «تم الرفع» text. Fix: add visible text «تم الرفع» (or `role="img" aria-label="تم الرفع"` on the tick).
- **Unread state** (C150): dot plus bold title, and the dot's label is ignored (see above).
- **From / to markers** (circle vs square): `C130:33–34`, `C30a:41–42`, `C21:22–25` (marked `aria-hidden`). Fix: visually-hidden «من:» / «إلى:». C23 and C06 already show «من / إلى» text.

### M-5 (Medium): bottom sheets and dialogs

- 10 sheets use `role="dialog"` or `role="alertdialog"` + `aria-label` but **no `aria-modal="true"`**: C06:35, C100:17, C10b:17, C10u:17, C101:17, C10x:17, C121:17, C180:19, C71:17, C72:17.
- The underlying screen (`<dc-import>`) is not made inert.
- Prefer `aria-labelledby` pointing at the visible `h2` over a duplicated `aria-label`.
- **Spec:**
  - Focus moves to the sheet heading on open and returns to the trigger on close.
  - Back gesture / Escape closes the sheet.
  - The background is `inert` / `importantForAccessibility="noHideDescendants"`.

### H-6 (High): OTP and authentication (C05, C05e, C05l)

- 4 single-character inputs: `<input aria-label="رقم 1" inputmode="numeric" maxlength="1" …>` (`C05-OTP.dc.html:25–28`).
  - **No `autocomplete="one-time-code"`.** The SMS autofill described in §8 («قراءة تلقائية») needs it on iOS. Android needs the SMS Retriever.
  - `maxlength="1"` per box breaks **pasting** a 4-digit code. 3.3.8 (Accessible Authentication) requires that copy/paste and autofill work.
  - No group name. Fix: wrap in `role="group" aria-labelledby="<h1 id>"`. Better: one visually-split input with `aria-label="رمز التحقق، 4 أرقام"`.
- `C05e:30` error `<p role="alert">` is good, but it is not tied to the inputs. Fix: `aria-describedby` → error id on each input (or on the single input).
- Countdowns are not specced:
  - «إعادة إرسال الرمز بعد 00:45» (`C05:31`) and the lock «10:00» (`C05l:22`) are static text.
  - Do **not** live-announce every second.
  - Announce once when resend becomes available or the lock ends (`role="status"`).
  - The lock itself is a security measure and is acceptable under 2.2.1.

### H-4 (High): status changes not announced (4.1.3)

Only `C05e` has a live region. No live region exists anywhere else, including these status changes:

- Ride and parcel status: «السائق في الطريق إليك» → «وصل» → «الرحلة جارية» (`C30a:24`, C30b, C30c, C50a, C50b, C70a, C70b, C90a).
- ETA chip «4 دقايق» (`C30a:25`).
- Search state: `C24:21`, `C45` (indeterminate `role="progressbar"`, no `aria-valuetext`).
- Upload «جاري الرفع · 60%» (`C84:40`), file-size error (`C84:47`).
- Incoming chat messages (C110).
- Duration stepper «4 ساعات» (`C63:54`, buttons «أضف ساعة» / «قلّل ساعة»).
- Toasts (§8).

**Fix:**

- `role="status"` (polite) on the sheet status line, ETA and stepper value.
- `role="alert"` for errors and «السائق وصل».
- `role="log"` on the chat list.
- `aria-valuetext="جاري البحث عن سائق"` on indeterminate bars.

### M-6 (Medium): input purpose and labels

- **No `autocomplete`** on any of the 26 inputs. The user's own data needs it under 1.3.5:
  - C03 phone → `autocomplete="tel-national"` + `type="tel"`.
  - C07 name → `autocomplete="name"`.
  - C161 email → `autocomplete="email"` + `type="email"`.
  - Third-party data (C42 recipient, C61 beneficiary) is exempt, but `autocomplete="off"` is fine there.
- `C21-Ride-Destination.dc.html:28–29`: fields have `aria-label="من"` / `"إلى"` but **no visible label**, and the «إلى» field relies on placeholder «وين تبغى تروح؟» (3.3.2). Show small «من» / «إلى» labels.
- Phone fields: the fixed «+966» prefix (`C03:26`, `C42:35`, `C61:52`) is not part of the input's name. Add `aria-describedby` → prefix, or a label «رقم الجوال (+966)».

### M-10 (Medium): upload screen

- `C84-Gov-Upload.dc.html:42`: `<span role="progressbar" aria-label="رفع وثيقة التأمين">` is determinate (60%) but has no `aria-valuenow`, `aria-valuemin` or `aria-valuemax`.
- `C84:44–47`: file error card «الملف 14 MB، والحد الأقصى 10 MB…» is not `role="alert"`, and the retry buttons «صوّر» / «اختر ملف» do not reference which document they belong to. Add `aria-describedby` → the card title.

### L-5 (Low): structure

- Repeated items (orders, notifications, addresses, cards, payment history) are `div`/`button` stacks. Only 3 `<ul>/<ol>` exist (C165, C82, C90a). Use lists so AT reports «1 of 5».
- Whole-card buttons (`Main:37`, `C130:30,38,46`) produce 60–100 word accessible names. Give a concise `aria-label` («رحلة اقتصادي إلى واجهة الرياض، السائق في الطريق») and move the details to `aria-describedby`.
- The home header button `Main:16` is named «أهلاً، محمد حي النرجس، الرياض» but its action is changing location. Use `aria-label="الموقع: حي النرجس، الرياض. تغيير"`.
- Card numbers «•••• 4821» are read as "bullet bullet…". Use `aria-label="مدى تنتهي بـ 4821"`.

### L-7 (Low): disabled radios

`C85-Gov-Schedule.dc.html:32–33` (Friday/Saturday) use `disabled` on `role="radio"`. They drop out of the reading order, so blind users never learn why those days are missing. Use `aria-disabled="true"` and keep them focusable. The explanation «الجهة مقفلة الجمعة والسبت» (`:36`) can be tied in with `aria-describedby`. Their `#8E9897` text is exempt as inactive.

---

## 6. RTL and bidirectional text

### What is already correct

- **LTR isolation is very consistent.** There are 87 `dir="ltr"` wraps covering:
  - phone numbers (`C05:21`, `C07:19`, `C160:17`, `C161:28`, `C162:21`)
  - plates (`Provider-Card:21`, `C131:30`)
  - card numbers and expiry dates (`C167:24,25,30`, `C124:29`)
  - order and ticket IDs (`#MSH-…`, `#SUP-58210`, `INV-…`)
  - file names (`C84:29,34`)
  - OTP boxes (`C05:24`) and phone fields (`C03:25`)
- No unwrapped LTR token was found except brand words («Apple Pay», «Visa», «STC Pay», «SMS», «PDF»). Those render correctly as isolated Latin runs.
- **Direction-dependent icons are correct for RTL:**
  - The back arrow is Iconsax ArrowRight (`M14.43 5.93…`) in all 55 screens.
  - Forward is ArrowLeft (`C02a:49`).
  - List chevrons point left (ArrowLeft2 `M15 19.92…`, 20 uses in 5 files).
  - The send icon is mirrored with `transform: scaleX(-1)` (`C110:38`).
  - The rating group uses `direction: ltr` so stars fill left to right, which is the conventional and correct choice.

### L-1 (Low)

- **Mirroring for English:** directional icons are hard-coded paths (55 back arrows, 20 chevrons, 1 next arrow). The app offers English (`C168-Language`). Mark them `.icon-dir` and apply `[dir=ltr] .icon-dir { transform: scaleX(-1) }` (iOS `.flipsForRightToLeftLayoutDirection`, Android `autoMirrored`).
- **«←» glyph** in route text is announced as "left arrow":
  - `C24:27` «حي النرجس ← واجهة الرياض»
  - `C45:27`, `C51:33` ×2, `C174:35`

  Wrap it: `<span aria-hidden="true">←</span><span class="sr-only">إلى</span>`.
- **Language of parts (3.1.2):**
  - `C168-Language.dc.html:26` has `lang="en"` (good).
  - The «English» button in `C02a-Onboarding.dc.html:17` lacks `lang="en"`.
  - «Simplified Tax Invoice» in `C134:23` lacks `lang="en"`.

---

## 7. Other significant issues

### H-7 / M-7: see §2 (stars, radio rings, timeline, borders).

### M-8 (Medium): dragging movement (2.5.7, new in 2.2)

`C164-Add-Address.dc.html:21`: «حرّك الخريطة لين يصير الدبوس على المكان». The pin is placed only by dragging the map. The «موقعي الحالي» button (`:23`) covers only the current location. **Add a single-pointer alternative:** an address search field (as in `C11:31`), tap-to-place on the map, or a «اختر من القائمة» option.

### M-9 (Medium): text resize and reflow (1.4.4 / 1.4.10 / 1.4.12)

Fixed heights combined with `white-space: nowrap` will clip text at 200% system font size (iOS Dynamic Type, Android font scale):

- Status pills: `height: 24px/28px; white-space: nowrap` (`Main:41`, `C90a:23`, `C130:31`…).
- Chips at `height: 36/40px`.
- Day tiles at `height: 64px` (C63, C85).
- Onboarding `<h1 style="font-size:30px; white-space:nowrap">` (`C02a-Onboarding.dc.html:45`) at 342 px width.

**Fix:** use `min-height`, allow wrapping, and add «اختبار على 200%» to the QA checklist.

### L-2 (Low): map SVG labels (`ui/assets/map/riyadh-olaya.svg`)

| Label type | Size / colour | Background | Ratio | Verdict |
|---|---|---|---|---|
| Major roads (طريق الملك فهد, شارع العليا, طريق العروبة, موسى بن نصير) | 10.5 px / 600, `#4F5D5B`, white 3 px halo | road white / ground `#F1F3F1` / expressway `#F6E8CB` | 6.89 / 6.18 / 5.68 | Pass (small) |
| Minor streets (ابن صنعين, ابن عقيل, أجياد, رقم 92) | **9.5 px**, `#7A8684`, white 2.5 px halo | white / `#F1F3F1` | **3.77 / 3.38** | **Fail** |
| Landmarks (برج المملكة, العليا مول) | 11 px / 600, `#6B7876`, halo `#F1F3F1` | `#F1F3F1` / buildings `#E3E7E5` | **4.12 / 3.68** | **Fail** |

These are images of text in a prototype asset. The real app uses Google Maps styling (§6). Still:

- In `ui/map-source/labels.json` / `render-map.ps1`, set all label fills to `#4F5D5B` (6.18 on ground, 5.52 on buildings) and minimum size 11 px.
- Apply the same in the production Cloud map style JSON.
- `alt=""` on the map image is acceptable because each map screen has a text equivalent: origin and destination in the sheet, and a search field.

### L-6 (Low): motion and timing

- These animations are implied but not specced:
  - OTP error «اهتزاز» (§8)
  - search pulse rings (`C24:16–17`)
  - spinner (`C84:39`)
  - indeterminate progress (`C24:24`)

  Under `prefers-reduced-motion` / Reduce Motion, replace the shake with the border and message only, and stop the pulse.
- Timeouts:
  - Ride search → «ما لقينا سائق» (C25) must offer «جرّب مرة ثانية» (it does).
  - The OTP lock (10:00) is security, so it is OK.
  - If payment or OTP sessions expire, warn the user and let them extend (2.2.1).

---

## Recommended changes to `ui/UI-GUIDELINES.md` (fixes most findings at the source)

| § | Current | Change to | Clears |
|---|---|---|---|
| 2 | `mute #8E9897`: placeholders only (but used for labels, values and times in §8) | `mute` → **`#646E6D`** (≥ 4.68 on every surface). Keep `#8E9897` as `disabled` only | C-1, L-4, H-7 radio ring |
| 2 | `success #2E8B3E`, `warning #B7791F` | Add `success-text #237033`, `warning-text #8A5A12`. Base colours for icons and borders only | H-1 |
| 2 | (none) | Add `border-strong #7D8786` (3.70 on white) for unselected chips, fields and dashed tiles | M-7 |
| 3 | `caption 12/20` for «ملاحظات صغيرة» | Status pills, step labels, prices and inline actions use **14 px** minimum. Nothing under 12 px except logos | M-3 |
| 4 | (none) | Add a `focus-ring` token (see H-3) | H-3 |
| 5 | Back and icon buttons: «دايرة 40» | **44** (visual 40 + 2 px hit-slop is acceptable) | M-1 |
| 8 | Text link `16/500` with no height | `min-height 44` / hit-slop for every text link | H-2 |
| 8 | Rating stars: «الفاضية إطار `primary-100`» | Empty: stroke `#6B7675`. Filled: sand + stroke `#9A6A14` | H-7 |
| 8 | Selection chip «إطار 1 `line`», height 36–40 | Border `border-strong`, `min-height 44` | M-1, M-7 |
| 8 | Text field «من غير إطار» | Optional 1 px `border-strong` in rest state | M-7 |
| 8 | OTP «قراءة تلقائية» | `autocomplete="one-time-code"`, paste fills all boxes, group label, `aria-describedby` → error | H-6 |
| 8 | Bottom sheet | `aria-modal`, inert background, focus to title, restore on close | M-5 |
| 8 | Toast / status lines | `role="status"`; errors `role="alert"` | H-4 |
| 8 | Toggle 44×26 | The whole row is the `switch`; specify an off-state track ≥ 3:1 | H-5 |
| 8 | Top bar «العنوان 16/500 في النص» | The title is the screen's `h1` | M-2 |

---

## Appendix: tool output used

Working files are in the session scratchpad, `…\scratchpad\`:

- `scan.ps1`: parser and contrast calculator.
- `scan2.ps1`: buttons, inputs, SVG and role inventory.
- `cr.ps1`: pair checker.
- `out\text.csv`: 1,237 text nodes with computed ratio.
- `out\el.csv`, `out\buttons.csv`, `out\inputs.csv`, `out\svg.csv`, `out\perfile.csv`.
