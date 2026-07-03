# Design guide — extracted from Figma

Visual reference for Phase 3 (screen) and Phase 4 (polish), read directly from a screenshot of the Figma flow the developer shared (six frames: Loading, Results, Pagination, Search Empty, Search Filled, No Results). This is a **best-effort visual read of a screenshot, not a pixel-measured export** — no exact hex codes or point values were extracted, only what's legible/inferable from the image. Treat every measurement below as "best guess, to be corrected after the developer's own side-by-side comparison with the real Figma file" (see the open blocker in `docs/PLAN.md`).

## 1. Header

- White bar, full width, fixed at the top of every screen.
- Centered circular logo mark: dark plum/maroon circle, white lowercase "e" (Enjoei brand mark). **Resolved**: sourced from Enjoei's own public PWA manifest icon (`https://www.enjoei.com.br/manifest-icons/enjoei-512.png`) — a real Enjoei brand asset, not a recreation — whose dominant color measured exactly `#61005D`, matching the `BrandPurple` value already confirmed via Figma Dev Mode. The source asset ships as a flat purple "e" mark with no circular backing (`maskable` PWA icons are drawn that way on purpose), so it was recolored (purple ink → white, white background → `BrandPurple`) and composited onto a filled circle to match the Figma header exactly. Stored as `EnjoeiLogo` in `Assets.xcassets`, shown via `navigationItem.titleView` in `ProductListViewController` instead of a text title.
- **Header bar container**: Figma Dev Mode measures the bar itself as 375×60pt, white background, with a 1.5pt bottom border in `#F1EEEC` (stored as the `HeaderDivider` color asset). **Deliberate developer call**: kept the system `UINavigationBar` at its default compact height (44pt) instead of building a fully custom 60pt header view — only the border color was matched exactly (via `UINavigationBarAppearance.shadowColor`), trading the extra ~16pt of header height for the stability of the system nav bar across iOS versions/safe areas.

## 2. Search bar

- Sits directly below the header, above the grid.
- Rounded/pill-shaped input, light background, subtle border/shadow.
- Placeholder text: lowercase **"buscar"**, gray.
- Magnifying-glass icon anchored inside the field, trailing edge.
- **When text is present**: a **"limpar busca"** text link appears immediately to the right of the search field (outside its rounded container), in the brand purple, vertically centered with the field. This same link is visible in both "Search Filled" and "No Results" — it does not disappear when there are no results, it's tied to "is there text in the field," not "are there results."
- **Open question, not resolved by the screenshot**: the "Results"/"Pagination" frames in the shared screenshot don't show a search bar at all, while `docs/ARCHITECTURE.md` already documents a decision that "the search bar stays fixed at the top of the grid in every state." Defaulting to the already-written architecture decision (always visible) since it predates this screenshot and may reflect a fuller view of the Figma file than this one crop — flag to the developer to confirm during her own Figma review.

## 3. Product grid (Results / Pagination)

- 2-column grid, consistent gutter between cards (small, roughly 8–12pt by eye).
- Screen-edge margin around the grid (roughly 16pt by eye).
- Each card: rounded corners on all four sides, moderate radius.
- **Image fills the entire card**, edge to edge — corrected after a closer screenshot: there is no separate white price strip below the photo. Background colors visible (peach, teal, olive, pink) come from the product photography itself, not app chrome.
- **Discount badge** (only when there's a discount): small rounded-rect, dark plum/maroon background, bold white text, format **"`{n}`% off"** (keeps the English word "off," common loanword in Brazilian retail — not "desconto" or "%OFF"). Floats over the **top-right** corner of the image, inset a few points from the edges.
- **Price pill**: a small white rounded-rect **floating over the bottom-left corner of the image** (not a separate strip beneath it), sized to fit its content with small padding:
  - With discount: current (sale) price shown **first, bold, in the brand plum/maroon color** — then the original (listed) price shown after, **gray, strikethrough**. The current price is colored, not black, specifically when discounted — a detail only visible in a closer screenshot, missed in the first pass of this guide.
  - Without discount: a single price, bold, **near-black** (not the brand color) — no second price, no badge.
- No visible price-per-unit or extra metadata beyond price and (conditionally) the badge — title/product name is **not shown on the card** in any of the six frames. (Worth confirming with the developer since `docs/ARCHITECTURE.md`'s table doesn't mention a title on the card either, and our `Product` entity does carry a `title` — it may be `accessibilityLabel`-only, not rendered visibly.)

## 4. Loading (skeleton)

- Same 2-column grid geometry as Results (same gutter/margin), so nothing shifts when real content replaces it.
- Each cell: one plain, light gray/off-white rounded rectangle — no separate image/price sub-placeholders visible, just a single solid block per cell.
- No shimmer visible in the static mockup (an animated shimmer is our own optional enhancement per `docs/ARCHITECTURE.md`, not something confirmed by the design).

## 5. No Results (empty state)

Search bar + its "limpar busca" link stay visible/pinned at the top even in this state. Below it, left-aligned (same margin as the grid), stacked top-to-bottom:

1. **Headline**, bold, two lines: "ué, não encontramos nadinha".
2. **Subtitle**, regular weight, gray, directly below: "que tal recomeçar do começo?".
3. **"limpar busca" button** — dark plum/maroon pill, bold white text, sized to its content (not full-width), some vertical gap above it. This is a *second* "limpar busca" affordance distinct from the inline link next to the search field — both exist simultaneously in this state.
4. **Mascot illustration** — a pink cartoon animal character (Enjoei brand mascot) holding a smartphone with a smiling face on its screen, surrounded by small scattered decorative shapes (a cloud, a small plant, a bicycle silhouette, an "X" mark). Positioned below the button, appears lower/right in the available space. **Resolved**: the developer exported the real asset from Figma, stored as `EmptyStateMascot` in `Assets.xcassets` and used directly in `EmptyStateView.swift`, replacing the earlier SF Symbol placeholder.

## 6. Color/type — measured values from Figma Dev Mode

The developer shared Figma Dev Mode inspector crops for the price/badge elements, giving exact values instead of a screenshot guess:

- **Brand color**: `#61005D` (exact hex, confirmed) — stored as the `BrandPurple` color asset in `Assets.xcassets`, used for the discount badge background, the current (sale) price text, the "limpar busca" link/button, and the logo mark.
- **Font family**: Figma specifies "ProximaNova" (a paid/commercial font, not an iOS system font). The developer decided to bundle **Montserrat** instead — an open-source (SIL OFL) geometric sans-serif close enough to ProximaNova (~85% visual similarity per the developer's own research) to use as a real, licensable substitute rather than an approximation. Bundled as `Montserrat-Variable.ttf` (`EnjoeiProducts/Resources/Fonts/`), registered via `UIAppFonts` in `Configuration/Info.plist`, accessed through `AppFont` (`EnjoeiProducts/Presentation/Shared/AppFont.swift`) so every call site stays a one-line change if the real ProximaNova file is ever provided.
- **Price text** (both current and strikethrough-original): size 12px, line height 100%, 0 letter-spacing. Figma measures weight 600 (semibold), but the developer deliberately chose **regular weight** here instead — a conscious visual call, not an unmeasured guess.
- **Badge text** ("33% off"): **semibold** (matches Figma's measured weight, unlike the price text above), white (`#FFFFFF`), centered, ~4-6pt padding inside the badge shape. Size deliberately reduced to 10px (Figma measures 12px) — another conscious developer call, not a measurement gap.
- **Discount badge container**: ~49×22pt for a 2-digit percentage — implemented as `greaterThanOrEqualToConstant` rather than a fixed 49pt, so it still fits a 1- or 3-digit percentage correctly.
- **Price pill container**: ~94×22pt for a two-price ("R$ 200 R$ 300"-length) string — implemented as auto-sizing (hug content + fixed padding) rather than a fixed 94pt, so a single, shorter price string doesn't leave dead space inside the pill.
- **Product card corner radius**: 16pt (confirmed via a rounded-corner padding diagram in Dev Mode).
- **Screen margin**: 16pt either side of the grid (confirmed — matches what was already implemented as a guess).
- **Grid gutter**: 8pt between columns/rows (confirmed — matches what was already implemented as a guess).
- **Primary text** (headline, no-discount price): near-black, matches `.label`.
- **Secondary text**: medium gray, matches `.secondaryLabel` — subtitle, strikethrough original price, search placeholder.
- **Surfaces**: white for the price pill/search field; light gray (`.systemGray6`) for skeleton blocks and the image placeholder background.
- **Appearance mode**: the Figma flow only has a light-mode spec — no dark-mode frames exist to validate against. Rather than invent an unverified dark palette, the app forces light mode app-wide (`window.overrideUserInterfaceStyle = .light` in `SceneDelegate`), so fixed-color surfaces like the white price pill and system-adaptive colors like `.systemBackground`/`.label` never drift from what was actually designed.

- **Search bar container**: 42pt tall (Dev Mode measures a 335×42 box at Figma's 375pt reference width, but the side margins are deliberately kept at 16pt — same as the grid's screen margin — so the search bar's edges align exactly with the card grid below it, confirmed against the running app). Implemented as an explicit height constraint on both the search row and the `UISearchBar` itself (without it, `UIStackView` has no natural cross-axis size to anchor to when neither it nor the adjacent `UICollectionView` has an independent height, and Auto Layout resolves the ambiguity by inflating the row instead of the grid).

Still unmeasured: headline/subtitle exact size, the "limpar busca" button's exact padding. Update this section as more Dev Mode values come in.

## 7. HIG audit — contrast & tap targets

Done at the developer's request, cross-checking the running app against Apple's Human Interface Guidelines (color contrast and interaction/tap-target sections), separate from the Figma visual read above.

- **Contrast, calculated (WCAG relative-luminance formula, not eyeballed)**:
  - `BrandPurple` (`#61005D`) on white ≈ **12.6:1** — well above the 4.5:1 minimum. Used for the discount badge, sale price, "limpar busca" link/button, logo.
  - System `.secondaryLabel` (RGB 60,60,67 @ 60% alpha) blended over white ≈ **3.44:1** — **fails** WCAG AA (4.5:1) at the small text sizes it was used at here (12–15pt). Replaced with a solid `ReadableGray` (`UIColor(white: 0.35, alpha: 1)`, `Presentation/Shared/ReadableGray.swift`) ≈ **7:1**, at: the empty-state subtitle, the strikethrough original price in `ProductCell`, and the error-state message label.
  - `.placeholderText`/`.tertiaryLabel` (30% alpha) ≈ 1.73:1 — left as-is; HIG treats placeholder/hint text as non-critical and exempt from the same bar as real content.
- **Tap targets (44x44pt HIG minimum)**:
  - `clearSearchButton` (inline "limpar busca" next to the search field) measured 121x34.33pt — visually correct per Figma's 42pt-tall search row, but under 44pt tall. Fixed by expanding only the *tappable* hit area (`ExpandedHitAreaButton`, overrides `point(inside:with:)`), not the visual frame, so the Figma-matched row height is untouched.
  - `retryButton` ("tentar novamente" in the error state) grew via `contentInsets` (13pt top/bottom) since it lives in a self-sizing stack with no external height constraint.
  - The empty-state SwiftUI "limpar busca" pill button got an explicit `.frame(minHeight: 44)` as a floor, independent of its exact padding/font metrics.
- **`ProductCell` accessibility**: added a combined `accessibilityLabel` (title + price, or title + sale price + original price + discount %) so VoiceOver reads one coherent phrase per card instead of silence or fragmented sub-labels.
- **Not changed**: icon sizes (search icon 16x16pt, logo 32x32pt), section margins (16pt), and the search field's 42pt height were all re-checked against HIG's general "give tappable icons breathing room" guidance and found consistent with the already-implemented Figma measurements — no violation found there.
- **Deferred, not in this pass**: Dynamic Type support for `AppFont` (a bigger, separate change) and a real tap action on `ProductCell` (functional gap, not a HIG compliance issue).

## How to use this doc

- Phase 3's spec (`docs/specs/03-product-list-screen.md`) implements against this guide's layout/behavior description.
- Remaining unmeasured spacing/typography and the mascot asset stay flagged in `docs/PLAN.md`'s "Open blockers" section until the developer reviews the running app next to the actual Figma file and corrects what's wrong here.
