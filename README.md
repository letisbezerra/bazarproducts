# EnjoeiProducts

iOS Pleno technical test for Enjoei — a liked products listing screen with loading state, infinite pagination, and local search.

## Features

Mandatory flows, per the test brief:
- Loading state (skeleton grid)
- Results listing — layout, prices, discount tags
- Infinite pagination — transparent, no blocking spinner
- Local search — filled state and "no results" empty state

Also included:
- Discount badge
- Image loading/caching (Kingfisher)
- Unit tests (ViewModel, mapper, repository)
- UI tests (XCUITest, covering all 4 mandatory flows)
- VoiceOver accessibility support (Dynamic Type, state-change announcements)

## Requirements

- Xcode 26.5+
- iOS 26.5+ (Simulator or device)

## Running the app

1. Open `EnjoeiProducts.xcodeproj` in Xcode.
2. Select the `EnjoeiProducts` scheme and any iOS Simulator.
3. Run (`Cmd+R`).

To run tests: select the `EnjoeiProducts` scheme, `Cmd+U`, or from the CLI:

```
xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Technical choices

Architecture: **Clean Architecture + MVVM**, split into `Domain` / `Data` / `Presentation` / `Core`, with UIKit (`UICollectionView` + Compositional Layout, no Storyboard/XIB), `async/await` for concurrency, and pagination via `UICollectionViewDataSourcePrefetching`. Search is filtered 100% locally over the already-loaded list, with no extra network calls. Kingfisher handles image loading/caching from the `image_public_id` returned by the API.

Full reasoning for every decision (why Clean+MVVM over VIPER/TCA, why `async/await` over Combine, security notes, testing strategy, and what was deliberately left out of scope) is documented in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## AI usage

AI (Claude Code) was used throughout as a development copilot. Every implementation started from a written specification, reviewed before any production code was generated, and every generated line was reviewed, adapted, and validated by me before being committed.

AI mainly helped with:
- generating boilerplate for the networking layer, DTOs/mappers, and the ViewModel/ViewController scaffolding;
- generating unit and UI test scaffolding;
- researching UIKit and accessibility APIs and Swift syntax (Compositional Layout, `UIFontMetrics` Dynamic Type scaling, `UIAccessibility.post` announcements);
- suggesting refactors and alternative implementations.

I was responsible for all architectural decisions, API analysis, debugging, accessibility validation, visual fidelity against the Figma design, and the final review of every AI-generated line. AI suggestions were treated as proposals rather than authoritative answers: whenever a suggestion affected architecture, accessibility, or visual behavior, it was verified in Xcode and the iOS Simulator before being accepted.

Every fix, in every phase, was validated by me in Simulator/Xcode against a concrete checklist before being committed — an AI report of "tests pass" was never taken as sufficient on its own.
