# Spec 00 — Project standards & tooling

Phase 0 of `docs/PLAN.md`. No feature code in this phase — this sets up the conventions and CI gate every later phase builds on.

## Goal

Lock in code style enforcement, add the one runtime dependency needed for images, and add a CI gate — before any feature code exists, so every subsequent phase is built and merged against these rules from the start.

## Inputs

- Xcode project already uses the file-system-synchronized group format (confirmed: any `.swift` file dropped into `EnjoeiProducts/` compiles automatically, no `.pbxproj` source-list edits needed). Adding SPM package *dependencies* (as opposed to source files) still requires editing `project.pbxproj`'s `XCRemoteSwiftPackageReference`/`XCSwiftPackageProductDependency` entries — there's no `Package.swift` in this project (it's an app target, not a package).
- No existing SPM dependencies, SwiftLint config, or CI workflow in the repo.

## Outputs

- `.swiftlint.yml` at the repo root.
- Two SPM package dependencies registered on the `EnjoeiProducts` target: SwiftLint (`https://github.com/realm/SwiftLint`, `from: 0.65.0`) as a build tool plugin, and Kingfisher (`https://github.com/onevcat/Kingfisher`, `from: 8.10.0`) as a linked library. Versions confirmed against the projects' real release tags (not guessed) at planning time.
- `.github/workflows/ci.yml`.

## Decisions & error cases

- **SwiftLint ruleset** (pragmatic, not maximal — a large default ruleset on a fresh project produces noise, not signal):
  - `force_unwrapping`: enabled outside test targets (test doubles are allowed to force-unwrap for setup brevity).
  - `line_length`: 120 warning / 150 error.
  - `unused_import`, `unused_declaration`: enabled.
  - Excluded paths: `**/*.generated.swift` (none exist yet, reserved for future), build artifacts.
  - If the plugin proves incompatible with this Xcode/Swift toolchain version during implementation, fall back to a `.swiftlint.yml` + a Run Script build phase invoking a locally-installed `swiftlint` binary — noted here so the fallback isn't a silent deviation if it happens.
- **Kingfisher** added now (Phase 0) even though it's first used in Phase 3, because dependency wiring is infrastructure work, not feature work — bundling it with the rest of the tooling setup avoids a second `pbxproj` dependency-graph edit later.
- **CI workflow**: triggers on `pull_request` targeting `develop` and `main`, and on `push` to `develop`/`main`. Single job: `macos-latest` runner, `xcodebuild test -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 16'`. No caching/matrix complexity added — a single-scheme test run is all this project needs; premature CI optimization for a one-target app would be unjustified complexity.
- No error cases to enumerate here (no runtime logic in this phase) — the equivalent is "CI must fail loudly if the build/test step fails," which is CI's default behavior, not something we implement.

## Verification

- `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 16' build` succeeds with both packages resolved.
- `import Kingfisher` compiles from any file in the `EnjoeiProducts` target (smoke-checked, then removed — no feature code in this phase).
- Pushing this branch triggers `.github/workflows/ci.yml` and it goes green.
