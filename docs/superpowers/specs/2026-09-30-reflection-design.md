# Reflection — Design Spec

Status: reviewed, 2026-10-01. All open questions closed. No code yet.
Plan: `docs/superpowers/plans/2026-10-01-reflection.md`.

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
   Below 5 resolved decisions, the card shows a threshold line instead of the control,
   for example "Patterns appear after 5 resolved decisions. 2 to go." The line shows
   wherever the surface is not `hidden`, for buyers and non-buyers alike. It is the
   useful empty state, and it is not a promotion.
2. **Decision reflection** (Decision Detail, below the revisit history). Shown for a
   decision that has a marked outcome and at least one note or revisit. Output:
   - Summary: how the decision aged.
   - What is repeating: 2 or 3 plain observations.
   - Next prompt: one question to carry into the next revisit.
3. **Clean Up Note** (Revisit, Mark Outcome and Log note fields). The user writes a
   rough note, then taps `Clean Up Note`. The app suggests a clearer version that keeps the
   meaning. The user accepts, edits or ignores it. It never rewrites by itself.
   Available on three note fields: Log, Mark Outcome and Revisit. The Edit Decision
   notes field is out of scope for v1.

Out of scope: chat, tags or categories from the model, generated scores, AI
notifications, onboarding for AI, Dashboard promotion, saved output, CloudKit,
widgets, new tabs.

## Rules for generated text

- User-triggered only. Nothing appears on a primary screen without a tap.
- Read-only, except Clean Up Note, which only suggests.
- No advice on what to choose. No score, diagnosis or personality label.
- Clean Up Note adds nothing the user did not imply. One mode, no tone picker.
- Output is ephemeral view state. Controls: `Copy` (Clean Up Note: `Use`, `Dismiss`).
- No `Refresh`. Greedy sampling gives the same output for the same input, so a Refresh
  tap would repeat the text. A change to the input (a new revisit, an edited note, a newly
  marked decision) clears the result, and the user taps again. An error state keeps
  `Try Again`.
- When nothing is shown, no card is shown. A `hidden` surface draws no title, no
  background and no empty card.

## Architecture

New feature folder `Offshoots/Reflection/`. Follow the file granularity rules: one
type of substance per file.

- **Policy (pure, tested without a model):**
  - `ReflectionGate`: maps model availability plus entitlement to one of four surface
    states: `hidden`, `notReady(reason)`, `paywalled`, `enabled`. Availability covers
    the OS version, device eligibility, Apple Intelligence, model readiness and locale
    support (`supportsLocale`). An unsupported locale gives `hidden`. No `freePreview`
    state (decided: no free preview).
  - `ReflectionEligibility`: decides which decisions and notes may produce output.
  - `ReflectionDigestBuilder`: condenses decisions into a small, stable struct for the prompt.
    The on-device model has a small context window, so the digest has a fixed size cap.
    Each note is cut to a maximum length (the plan uses 1,500 characters), and the
    digest is tested against that cap.
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
- Ineligible device, Apple Intelligence off or unsupported locale: `hidden`. Model not
  ready: `notReady`, a disabled control with the reason. Simulator: assumed to have no
  model, so `hidden`. Real output needs a device (iPhone 17, the device of record).
- Unverified: the Xcode 26+ simulator may use the host Mac's model when Apple
  Intelligence is on for that Mac. To check, print `SystemLanguageModel.default.availability`
  in a simulator run on the Mac mini. If the model is available, the simulator can show
  real output, and the fake generator stays for tests and screenshots.
- Re-check the framework signatures against the installed SDK before writing the live
  service. The Contrition plan was written against an earlier Xcode 27 seed. Check
  `xcodebuild -version` on the machine in use.

## Monetization

**Model: one-time purchase (non-consumable), $5.99.** Decided 2026-10-01.

- Family Sharing: off. App Store Connect lets you turn it on later, but not off after
  that. Off is the safe v1 choice.
- No subscription is planned. The entitlement still checks a product-ID list, which costs
  nothing and needs no rework if a subscription ever ships.
- The gate reads one value: `isUnlocked`.
- `ReflectionEntitlement` sets it from `Transaction.currentEntitlements` at launch and
  keeps it current with `Transaction.updates`. A revoked (refunded) transaction does not
  count, and a refund locks the surfaces again with no relaunch.
- Paywall copy shows `Product.displayPrice` from StoreKit and hard-codes no price. It may
  say "one-time purchase", because that is now true.
- Paywall framing: "Unlock Reflection". Sell better reflection, not an AI bundle. Bullets:
  pattern highlights, decision reflections, clearer notes. Avoid "AI coach", "ask anything",
  "personal advisor", "predict regret".
- Show the paywall in context, at the tap on a locked surface. No onboarding.
- Needs a restore path (`AppStore.sync` through a Settings row).
- Gate the paywall on model availability. Never sell the unlock on a device that cannot use it.
- Context: the Tip Jar was removed on 2026-09-26 (see `DECISIONS.md`), so this is the
  first in-app purchase since the 2.0.0 relaunch. It adds an IAP to App Review.
- App Review risk: the paywall is hidden on a device that cannot run the model. If the
  reviewer's device cannot run it, the reviewer cannot find the IAP. Submit a review
  screenshot of the paywall and a review note: "Needs an Apple Intelligence-capable
  device on iOS 26 or later."
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

- **Price and model.** One-time price, and the subscription entry point, if any. **Decided: $5.99, One time** 📅 2026-10-01
- **Save or regenerate?** This spec says regenerate on demand. Saving adds a data model and
  a sync question. **Decided: Regenerate** 📅 2026-10-01
- **Free preview.** Give one free reflection to show the value? It adds a `freePreview` gate
  state and a stored flag. Default: no, for v1. **Decided: No** 📅 2026-10-01
- **Family Sharing** for the unlock: on or off. **Decided: Off** 📅 2026-10-01
- **Minimum data for Patterns.** Suggested: 5 resolved decisions. Tune with the fixtures. **Agreed** 📅 2026-10-01
- **Language and locale.** The model supports a limited set. Surfaces hide when the locale
  is unsupported. **Agree, no localization exists as far as I am aware** 📅 2026-10-01
