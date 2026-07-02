# My Engineering Approach

Context: iOS Pleno technical test for Enjoei. The job posting explicitly cites shape up/basecamp culture and full transparency on task progress — that's why I work spec-first (not spec-driven/SDD): the spec (here, `docs/ARCHITECTURE.md`, plus one `docs/specs/*.md` per phase) is written and validated before code, but after that the implementation and all technical judgment are mine, not the AI's. AI is a copilot, not the pilot.

Four docs, four jobs — don't mix their content: `docs/CONTEXT_TEST.md` is what's mandatory (Enjoei's literal requirements, not to be reinterpreted); `docs/ARCHITECTURE.md` is how we chose to meet it (our decisions and their reasoning); `docs/PLAN.md` is the phase-by-phase roadmap and its live status (check this first in a new session to know what's already done); `docs/specs/*.md` is the per-phase detail written before implementing each phase.

I work spec-first: before generating anything, I understand the problem, map the codebase, run existing tests to establish a baseline, and decompose the feature into ordered tasks — dependencies, what can run in parallel, what must be sequential. Only then I define the spec — input, output, error cases — and generate.

I review every diff the agent produces — not just for correctness, but for consistency with the existing codebase. If something looks off, I fix the context I gave, not the output I got. I watch for hallucinations, context rot, and sycophancy — when the agent fails, I fix the system rules, not the ephemeral output.

My priorities in any solution: correctness first, then security and privacy, then simplicity, then elegance. I follow existing patterns unless they introduce a specific risk, and I flag improvements separately rather than changing scope mid-task.

I use tests to verify behavior, not to prove the code compiles. Elegant solutions do exactly what they need to — clear structure, intentional naming, nothing that doesn't belong. No dead code, no unnecessary comments, no debug artifacts. For UI work, elegance also means visual fidelity: matching the design spec's spacing, color, and typography exactly, not an approximation — aesthetics are part of the bar, not a nice-to-have on top of it.

Not everything belongs to the agent. Decisions involving sensitive data, compliance constraints, or flows that affect end users directly stay under human review — in healthcare, a wrong output isn't just a bug.

When I'm uncertain, I make the assumption explicit before generating. I'd rather name what I don't know than silently get it wrong.

Quality is not a layer added at the end — it is built into every decision.

The runtime here is Apple's native toolchain — no Docker (there's no containerized iOS simulator). Builds and tests always go through `xcodebuild` (CLI) or local Xcode, running on the Simulator or a device.

Limited time is exactly why this structure matters — without a clear process, time pressure becomes an excuse for low quality.
