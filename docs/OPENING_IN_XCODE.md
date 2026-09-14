---
title: Bridge™ Swift · Getting it onto a Mac and into Xcode
audience: Internal, Armada.
prepared_by: Taylor, for M. David King
date: 2026-09-14
---

# 1 · Get the code

It is already on GitHub. On the Mac:

    git clone https://github.com/y426r279pm-cyber/ARMADA_Genesis.git
    cd ARMADA_Genesis
    git checkout claude/web-portal-swift-conversion-6col45

If you would rather not use git, the same tree is in the tarball sent alongside
this note; unpack it anywhere.

You need **Xcode 15.3 or newer** (Swift 5.9, SwiftData, `@Observable`) and a Mac
on macOS 14 or newer.

# 2 · Find the compile errors first — no Xcode project needed

This is the fastest route, and the one to take first.

    swift build --package-path Bridge

`BridgeKit` is a library, so the whole port — every screen, the chain, the
rails — compiles from the command line in one command. None of it was written
against a compiler, so expect errors on the first run. They will be ordinary:
a renamed API, an argument label, an actor-isolation complaint.

Then the tests:

    swift test --package-path Bridge

Three of them are worth watching:

| Filter | What it proves |
|---|---|
| `CanonicalSealTests` | a ledger sealed in the browser verifies here, byte for byte |
| `StringAuditTests`   | no string claims fiscal validity or control remediation |
| `DemoModeTests`      | no model name survives into the client seed |

`CanonicalSealTests` is the one that matters most. If it passes, the two builds
agree about the thing hardest to agree about.

# 3 · Open it in Xcode

    open Bridge/Package.swift

Xcode opens the package directly — no `.xcodeproj` needed. You get the whole
source tree, ⌘B to build, ⌘U to test, and full navigation. For fixing what the
compiler finds, this is all you need.

# 4 · Make it run

`BridgeKit` is a library and there is no app target yet, so steps 2 and 3 build
and test the console without running it. To get a window:

1. **File → New → Project → macOS → App.** Name it `Bridge`, interface SwiftUI,
   language Swift. Save it *outside* `Bridge/` — say at the repository root as
   `BridgeApp/` — so it does not collide with the package.
2. **Delete** the `ContentView.swift` and `BridgeApp.swift` Xcode generated.
3. **File → Add Package Dependencies → Add Local…** and choose the `Bridge`
   folder. Add the `BridgeKit` library to the app target.
4. **Drag in `Bridge/App/BridgeApp.swift`** — the real one, with `@main`.
5. **Target → Signing & Capabilities:** add *App Sandbox*, *Keychain Sharing*
   and *Outgoing Connections (Client)*. Or point the target's
   `CODE_SIGN_ENTITLEMENTS` at `Bridge/App/Bridge.entitlements`, which already
   declares exactly those and nothing else.
6. **Copy the two keys from `Bridge/App/Info.plist`** into the target's Info tab:
   `NSFaceIDUsageDescription` and `ITSAppUsesNonExemptEncryption`.

`NSFaceIDUsageDescription` is not optional. Without it, the approval gate's call
to `LocalAuthentication` fails on a Face ID machine. It fails *safely* — the gate
reads an unanswered authenticator as `.ambiguous` and refuses — but nothing can
be approved and the reason would be obscure.

⌘R and the front door appears. Sign in as Enterprise Admin to see all 22 screens.

# 5 · Turn on the local model

Off by default, because the MLX adapter is the one file written without a
compiler to check it (see the header of `Core/MLXEngine.swift`).

1. Uncomment the two blocks in `Bridge/Package.swift` — the `dependencies:` at
   package level and at target level.
2. Resolve. Xcode fetches `mlx-swift-examples`.
3. Build. Fix what it says about the four calls in `MLXEngine.swift`: the module
   names, how a container loads, how a chat prompt is shaped, how tokens stream.
   Nothing outside that file references MLX.
4. Put the weights in the Hub cache **before** any demo. Bridge never downloads
   during a session — absent weights report "weights not on this machine", by
   design. On the 16 GB demo machine use Qwen 2.5 7B at 4-bit, with the 3B as
   the fallback; `docs/ON_DEVICE_MODEL.md` has the budget.

Without MLX the console runs fine and says plainly that there is no local model.
The keyed rails still work with a key in Settings.

# 6 · Build the client demo

    tools/make_client_build.sh

Two steps, both required: the seed is swapped for one with no model names in it
at all, and the binary is compiled with `-DCLIENT_DEMO` so the branches that
would print a node count or a price are not in it. `docs/DEMO_MODE.md` explains
why either alone is a half measure.

Before any client session:

    swift test --package-path Bridge --filter DemoModeTests

# 7 · Regenerating from the prototype

When RC2.2 lands, drop it in as `source/Bridge_RC2_1.html` and:

    ./tools/extract_all.sh

That regenerates the theme, routes, roles, strings, icons, seed, schema and the
redacted client seed, then checks string coverage, seed idempotency and the
chain. The generated files carry a header saying not to edit them by hand.

`UI/ScreenHost.swift` is the exception — written once, maintained by hand. Its
switch has no `default`, so a new route in RC2.2 breaks the build until somebody
decides what it shows. That is the right moment to decide it.

# What to expect on the first build

Nothing in `Bridge/` has been compiled. Across the five phases, reading for
errors caught nine real ones — `await` in a `where` clause, a mutable capture in
a `@Sendable` closure, three schema mismatches against the generated models. A
compiler will find more, and they will be shallow: names, labels, isolation.

The parts most likely to need a hand, in order:

1. `Core/MLXEngine.swift` — only if you enable it in step 5.
2. Actor isolation around `Taylor`, `DeviceModel` and the rails, where
   `@MainActor` meets `Sendable` closures.
3. `Graphics/` — `Canvas` and `Path` signatures.
4. SwiftData `@Query` in views whose models carry optional fields.

The logic underneath — the seven match rules, the approval gate, the energy
arithmetic, the canonical encoder, the policy diff — is covered by tests, so once
it compiles you will know quickly whether it is right.
