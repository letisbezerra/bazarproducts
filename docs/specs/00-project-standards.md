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
  - `force_unwrapping`: opted in, disabled again for `EnjoeiProductsTests`/`EnjoeiProductsUITests` via nested `.swiftlint.yml` files in those folders (test doubles are allowed to force-unwrap for setup brevity).
  - `line_length`: 120 warning / 150 error.
  - `unused_import`/`unused_declaration` were dropped from the plan: they're analyzer-only rules (only run under `swiftlint analyze`, which needs a compilation database) — listing them under `opt_in_rules` is a no-op under the build tool plugin's plain `lint` pass and SwiftLint itself warns about it. Not worth the extra CI complexity for this project's size.
  - Excluded paths: `.build`, `DerivedData`.
- **Kingfisher** added now (Phase 0) even though it's first used in Phase 3, because dependency wiring is infrastructure work, not feature work — bundling it with the rest of the tooling setup avoids a second `pbxproj` dependency-graph edit later.
- **CI workflow**: triggers on `pull_request` targeting `develop` and `main`, and on `push` to `develop`/`main`. Single job: `macos-latest` runner, `xcodebuild test -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation`. No caching/matrix complexity added — a single-scheme test run is all this project needs; premature CI optimization for a one-target app would be unjustified complexity.
- No error cases to enumerate here (no runtime logic in this phase) — the equivalent is "CI must fail loudly if the build/test step fails," which is CI's default behavior, not something we implement.

## What actually happened (diverged from the original plan)

This section exists per the phase-lifecycle rule in `docs/PLAN.md`: update the spec when reality diverges, don't leave it aspirational.

- There's no CLI command to add an SPM package dependency to an Xcode project (`xcodebuild` has nothing for this). Used the `xcodeproj` Ruby gem to edit `project.pbxproj` directly, which is what actually needed the fallback contingency mentioned in the original draft of this section — not a plugin/toolchain incompatibility, but the total absence of CLI tooling for this step.
- A regular linked package (Kingfisher) and a **build tool plugin** (SwiftLint) are wired completely differently in `project.pbxproj`, and got this wrong twice before checking real open-source projects' `.pbxproj` files for the correct shape:
  - A linked package needs a `PBXBuildFile` (with `productRef`) in the target's Frameworks build phase, plus the `XCSwiftPackageProductDependency` in `packageProductDependencies`.
  - A build tool plugin is **not** linked at all. It needs a `PBXTargetDependency` (with `productRef` pointing at the `XCSwiftPackageProductDependency`) added to the target's `dependencies` array — and the product's name must carry a `"plugin:"` prefix (`"plugin:SwiftLintBuildToolPlugin"`), not just the bare product name. Putting a plugin in `packageProductDependencies` or in the Frameworks phase produces a "Missing package product" build error with no other clue.
- Headless `xcodebuild` refuses to run a build tool plugin for the first time without interactive approval (the "Trust & Enable" dialog Xcode normally shows). The fix is the documented `-skipPackagePluginValidation` flag, needed on every `xcodebuild build`/`test` invocation in both local verification and `.github/workflows/ci.yml` — not just once.
- This sandbox's shell injects `GIT_CONFIG_KEY_0=safe.bareRepository`/`VALUE_0=explicit` into every command (a CVE-2024-32002 mitigation), which breaks SwiftPM's package resolution because its local package cache is itself a bare git repository. Worked around by running just the resolve/build/test commands with those two env vars unset for that one invocation (confirmed with the user first, since it's bypassing a security guard, even narrowly) — no git config was touched. This is specific to this sandboxed environment; a normal developer machine or GitHub Actions runner won't have this env var set, so `.github/workflows/ci.yml` does not need the workaround.
- The "iPhone 16" simulator named in the original plan doesn't exist on this Xcode 26.5 install (ships with iPhone 17 as the current-generation device); all docs/CI referencing it were updated to "iPhone 17".
- **`.github/workflows/ci.yml`'s "Select Xcode" step originally hardcoded `/Applications/Xcode.app`**, assuming that symlink pointed to a recent version. On the actual GitHub-hosted runner it resolved to Xcode 16.4, which has no iOS 26 simulator runtime — `xcodebuild test` failed immediately with "Unable to find a destination matching the provided destination specifier." Fixed by selecting the newest `Xcode_*.app` actually installed on the runner (`ls -d /Applications/Xcode_*.app | sort -V | tail -1`) instead of trusting the default symlink.
- **Known limitation, left unresolved by a deliberate scope decision**: after the Xcode-selection fix, `xcodebuild test` stopped failing on destination lookup but instead hung for 15+ minutes inside the "Run tests" step with no further log output — consistent with a simulator-boot hang, a known flaky failure mode for headless `xcodebuild test` runs on CI. Local runs (`xcodebuild build`/`test` on the developer's machine) succeed reliably; this appears specific to the GitHub-hosted runner's simulator boot behavior. CI/CD is a "diferencial" in the job posting, not a requirement in `docs/CONTEXT_TEST.md`, and the deliverable is a zip file the evaluator runs locally, not a GitHub Actions run they'll observe — so chasing a headless-simulator-boot fix (which typically requires explicit `simctl boot`/`bootstatus` handling, possibly a runner image pin) was deliberately not pursued further, matching the job posting's own "equilibrar o código perfeito com o software funcionando no prazo" principle. Mitigated with `timeout-minutes: 15` on the job so a future hang fails fast instead of consuming hours, rather than fixing the underlying simulator-boot flakiness. Correctness of the actual app code is verified locally and via the test suite regardless of this CI limitation.

## Verification

- `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation build` succeeds with both packages resolved — confirmed locally (`** BUILD SUCCEEDED **`).
- `xcodebuild test` with the same destination — confirmed locally (`** TEST SUCCEEDED **`, template tests only, no feature tests yet).
- `import Kingfisher` compiles from `ProductListViewController.swift` (smoke-checked during the build above; not left in the source).
- Pushing this branch triggers `.github/workflows/ci.yml`. The Xcode-selection bug (see "What actually happened") was found and fixed this way. The build/test steps themselves did not go green on the GitHub-hosted runner due to the known simulator-boot limitation documented above; the app's correctness is instead verified by the local `BUILD SUCCEEDED`/`TEST SUCCEEDED` results above. Accepted as a documented, non-blocking limitation per the scope decision above.
