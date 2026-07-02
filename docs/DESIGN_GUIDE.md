# Design guide — extracted from Figma

Visual reference for Phase 3 (screen) and Phase 4 (polish), read directly from a screenshot of the Figma flow the developer shared (six frames: Loading, Results, Pagination, Search Empty, Search Filled, No Results). This is a **best-effort visual read of a screenshot, not a pixel-measured export** — no exact hex codes or point values were extracted, only what's legible/inferable from the image. Treat every measurement below as "best guess, to be corrected after the developer's own side-by-side comparison with the real Figma file" (see the open blocker in `docs/PLAN.md`).

## 1. Header

- White bar, full width, fixed at the top of every screen.
- Centered circular logo mark: dark plum/maroon circle, white lowercase "e" (Enjoei brand mark). Not the app's own asset to design — likely already provided as a brand asset, or recreate simply with `AccentColor` + SF Symbol/text if no asset is exported.

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
4. **Mascot illustration** — a pink cartoon animal character (Enjoei brand mascot) holding a smartphone with a smiling face on its screen, surrounded by small scattered decorative shapes (a cloud, a small plant, a bicycle silhouette, an "X" mark). Positioned below the button, appears lower/right in the available space. **This exact asset is not something extractable from the shared screenshot as a clean, transparent image file** — still an open blocker (`docs/PLAN.md`) until the developer exports it from Figma, or we agree on a stand-in.

## 6. Color/type — measured values from Figma Dev Mode

The developer shared Figma Dev Mode inspector crops for the price/badge elements, giving exact values instead of a screenshot guess:

- **Brand color**: `#61005D` (exact hex, confirmed) — stored as the `BrandPurple` color asset in `Assets.xcassets`, used for the discount badge background, the current (sale) price text, the "limpar busca" link/button, and the logo mark.
- **Price text** (both current and strikethrough-original): font family "ProximaNova," weight 600 (semibold), size 12px, 0 letter-spacing. **ProximaNova is a paid/commercial font, not an iOS system font** — the developer decided to use the system font (San Francisco) at the same size/weight (12pt semibold) as a stand-in rather than license/bundle the real font file, at least for now. If the real font is ever provided, only `ProductCell`'s label `.font` assignments need to change.
- **Discount badge**: ~49×22pt.
- **Price pill**: ~94×22pt container.
- **Primary text** (headline, no-discount price): near-black, matches `.label`.
- **Secondary text**: medium gray, matches `.secondaryLabel` — subtitle, strikethrough original price, search placeholder.
- **Surfaces**: white for the price pill/search field; light gray (`.systemGray6`) for skeleton blocks and the image placeholder background.

Everything not listed above (headline/subtitle exact size, grid gutter/margin, corner radii) is still an unmeasured guess — update this section as more Dev Mode values come in.

## How to use this doc

- Phase 3's spec (`docs/specs/03-product-list-screen.md`) implements against this guide's layout/behavior description.
- Remaining unmeasured spacing/typography and the mascot asset stay flagged in `docs/PLAN.md`'s "Open blockers" section until the developer reviews the running app next to the actual Figma file and corrects what's wrong here.
