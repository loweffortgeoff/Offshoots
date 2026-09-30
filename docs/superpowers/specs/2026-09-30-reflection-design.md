# Reflection — Design Spec

Status: draft for review, 2026-09-30. No code yet.

Source: the Contrition "Paid Reflection Unlock" sketch and its Apple Intelligence UI
plan (Dev Workstation, `App-Dev-Notes/Archived Projects/Contrition/`). This spec
adapts that work to Offshoots.

## Goal

Add an optional, on-device, user-triggered text layer to Offshoots. It helps the user
read what their decisions say over time. It is sold as a paid unlock called
**Reflection**. The free app stays complete.

## Scope

Three surfaces. Each one is triggered by the user, shows inline, and is not saved.

1. **Patterns** (Insights tab). Short observations across resolved decisions.
   Build first. The digest comes from existing `AnalyticsEngine` output plus
   category, stakes, expected-versus-actual and revisit notes.
2. **Decision reflection** (Decision Detail, below the revisit history). Shown for a
   decision that has a marked outcome and at least one note or revisit. Output:
   - Summary: how the decision aged.
   - What is repeating: 2 or 3 plain observations.
   - Next prompt: one question to carry into the next revisit.
3. **Clean Up Note** (Revisit, Mark Outcome and Log note fields). The user writes a
   rough note, then taps `Clean Up Note`. The app suggests a clearer version that keeps the
   meaning. The user accepts, edits or ignores it. It never rewrites by itself.
   Available on every note field (Log, Mark Outcome, Revisit).

Out of scope: chat, tags or categories from the model, generated scores, AI
notifications, onboarding for AI, Dashboard promotion, saved output, CloudKit,
widgets, new tabs.

## Rules for generated text

- User-triggered only. Nothing appears on a primary screen without a tap.
- Read-only, except Clean Up Note, which only suggests.
- No advice on what to choose. No score, diagnosis or personality label.
- Clean Up Note adds nothing the user did not imply. One mode, no tone picker.
- Output is ephemeral view state. Controls: `Refresh` and `Copy` (Clean Up Note:
  `Use`, `Dismiss`).

## Architecture

New feature folder `Offshoots/Reflection/`. Follow the file granularity rules: one
type of substance per file.

- **Policy (pure, tested without a model):**
  - `ReflectionGate`: maps model availability plus entitlement to a surface state:
    `hidden`, `enabled`, `paywalled`. (`freePreview` is added only if the free preview
    question below resolves to yes.)
  - `ReflectionEligibility`: decides which decisions and notes may produce output.
  - `ReflectionDigestBuilder`: condenses decisions into a small, stable struct for the prompt.
  - `ReflectionPromptBuilder`: pure prompt and instruction strings.
- **Generation:** `ReflectionGenerating` protocol, with a `LiveReflectionService` as the
  only file that imports `FoundationModels`. Each call makes a new `LanguageModelSession`
  with fixed instructions, uses a `@Generable` output type, greedy sampling and a token cap.
  Tests use a fake generator.
- **View state:** a generic `ReflectionViewState` (idle, loading, result, error) and small
  inline card views.
- **Naming:** `Decision.reflection` already exists. It is the note the user writes in
  Mark Outcome. The feature therefore uses the prefix `Reflect…` in types only where no clash
  occurs, and the user-facing name "Reflection" is for the unlock. Keep the two meanings
  apart in code comments.

### Platform

- The app deploys to **iOS 18.6**. Foundation Models needs **iOS 26**, and needs Apple
  Intelligence to be on and the device to be eligible.
- Gate all Foundation Models code with `#available(iOS 26, *)`. The Live service and any
  view that touches it sit behind that check. On iOS 18.6 to 25.x, the surfaces are `hidden`.
- Ineligible device or Apple Intelligence off: `hidden`. Model not ready: disabled
  control with the reason. Simulator: no model, so `hidden`. Real output needs a device
  (iPhone 17, the device of record).
- Re-check the framework signatures against the installed SDK before writing the live
  service. The Contrition plan was written against an earlier Xcode 27 seed. Check
  `xcodebuild -version` on the machine in use.

## Monetization

**Model: paid unlock, priced later.**

- Launch plan: a **one-time purchase** (non-consumable), with a price near the Contrition
  sketch of $4.99. The price is **not settled**.
- **A low-cost subscription is not ruled out.** If it comes, it sits at a much lower entry
  point than typical. This overrides the Contrition guardrail "No subscriptions".
- **The design does not depend on the price or on the purchase type:**
  - The gate reads one value: `isUnlocked`.
  - `ReflectionEntitlement` sets it from `Transaction.currentEntitlements`, checking any
    product ID in a list. A non-consumable and a subscription in that list both unlock.
  - Paywall copy shows `Product.displayPrice` and subscription terms from StoreKit. It
    hard-codes no price and does not say "one-time".
  - A buyer of the one-time unlock keeps access if a subscription is added later, because
    that purchase stays in the list.
- Paywall framing: "Unlock Reflection". Sell better reflection, not an AI bundle. Bullets:
  pattern highlights, decision reflections, clearer notes. Avoid "AI coach", "ask anything",
  "personal advisor", "predict regret".
- Show the paywall in context, at the tap on a locked surface. No onboarding.
- Needs a restore path (`AppStore.sync` through a Settings row).
- Gate the paywall on model availability. Never sell the unlock on a device that cannot use it.
- Context: the Tip Jar was removed on 2026-09-26 (see `DECISIONS.md`), so this is the
  first in-app purchase since the 2.0.0 relaunch. It adds an IAP to App Review.
- Privacy: no network calls, no analytics. All generation runs on the device.

## Testing

- Unit tests (Swift Testing): gate mapping, eligibility, digest builder, prompt builder,
  view-state transitions, entitlement mapping with a fake transaction source. Fixtures under
  `docs/fixtures/`.
- UI behavior: check on the simulator with the fake generator (a debug launch flag or an
  injected service). Real model output: check on the iPhone 17.
- StoreKit: a local `.storekit` configuration file for the simulator.
- VoiceOver labels and Dynamic Type for every card, as the design contract requires.

## Suggested chunks (each a reviewable stop)

1. Policy layer, protocol and fakes, with tests. No SDK, no UI.
2. Live service and Patterns on Insights, unlocked through a debug flag.
3. Decision reflection on Decision Detail.
4. Clean Up Note on the three note fields.
5. StoreKit entitlement, paywall, restore row.
6. Docs, listing and release-notes pass.

## Open questions

- **Price and model.** One-time price, and the subscription entry point, if any. Decide
  before chunk 5.
- **Save or regenerate?** This spec says regenerate on demand. Saving adds a data model and
  a sync question.
- **Free preview.** Give one free reflection to show the value? It adds a `freePreview` gate
  state and a stored flag. Default: no, for v1.
- **Family Sharing** for the unlock: on or off.
- **Minimum data for Patterns.** Suggested: 5 resolved decisions. Tune with the fixtures.
- **Language and locale.** The model supports a limited set. Surfaces hide when the locale
  is unsupported.
