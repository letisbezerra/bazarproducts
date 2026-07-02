# EnjoeiProducts

iOS Pleno technical test for Enjoei — a liked products listing screen with loading state, infinite pagination, and local search.

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

_To be filled in as the implementation progresses — this section will describe concretely where AI was used (e.g. scaffolding, refactors, test generation, syntax lookups) and where decisions were made and reviewed by hand, as requested in the test brief._
