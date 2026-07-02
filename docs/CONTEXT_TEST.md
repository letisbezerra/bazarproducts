# Enjoei — iOS Pleno Technical Test Brief

Literal requirements as sent by Enjoei for this technical test. This is the source of truth for what's mandatory — `docs/ARCHITECTURE.md` and `docs/specs/*.md` document *how* we chose to meet these requirements, not *what* is required.

## 1. Scope: the full package

One screen — a product listing — with several mandatory extra states. All variations below are required, not optional:

- **Loading**: some visual treatment while the API call is in flight.
- **Results listing**: products rendered respecting the layout, prices, and discount tags.
- **Infinite pagination**: scrolling near the bottom transparently loads the next page (no full-screen blocking spinner).
- **Search**: a field that filters results **locally** by text. Two states get special attention: search filled with matches, and — most importantly — the no-results state: "ué, não encontramos nadinha".

Design reference: Figma file (password: `REDACTED`), which contains every state above.

## 2. AI usage — the ground rules

AI tools (ChatGPT, Copilot, Claude, etc.) are explicitly welcome. The deal:

- AI is the copilot, the developer is the pilot — full ownership of the code is required.
- If AI generates something outside good practices, cleaning it up is the developer's responsibility.
- Evaluation focuses on: the chosen architecture, quality of abstractions, test coverage, and fidelity to the visual details — not on whether AI was used.

## 3. API & data

- Endpoint: `GET https://www.enjoei.com.br/api/v5/users/enjoei-pro/products/liked?page=1` (public, same one used by Enjoei's own liked-products list on web/apps).
- The `page` query parameter drives pagination.
- Images: build the final URL by concatenating the API's `image_public_id` into the image service's URL structure. Example:
  `https://photos.enjoei.com.br/public/500x500/czM6Ly9waG90b3MuZW5qb2VpLmNvbS5ici9wcm9kdWN0cy82NTMwNzkxLzlmZGY5ZWZjNTk5NTdkMDY4YjU4YmFjMzNmMmNmM2YxLmpwZw`
  (We verified directly against the live API that `image_public_id` is already the base64 string the CDN expects — see `docs/ARCHITECTURE.md` Context section for the full finding.)

## 4. What's expected from a Pleno-level dev

- A modern, testable architecture (MVVM, Clean, etc.).
- Tests are expected and welcomed — demonstrate that business logic and success/failure flows are protected. (AI is explicitly encouraged for writing tests.)
- Native tech: Swift. UIKit is preferred; SwiftUI is acceptable if it fits the chosen architecture better.
- Third-party dependencies may be installed freely as needed.

## 5. Delivery

- Zip the whole project and send it over.
- The README must cover, beyond basic run instructions:
  1. **Technical choices** — explain the architecture, libraries used, and the reasoning behind the solution. Justifying decisions matters.
  2. **AI superpowers** — full transparency on how AI was used in this challenge (boilerplate generation? refactoring complex logic? syntax lookups?). No answer here is penalized — the goal is understanding how the tool fits into the workflow.
