# Echo (working title)

A push-to-talk dictation app for macOS, inspired by Wispr Flow: hold a key,
talk, release — your words get transcribed, cleaned up, and pasted into
whatever app you're using. Built as a personal tool, not a Wispr Flow
clone-for-distribution.

This is a **skeleton**: it's structured to actually work end-to-end, but it
was written without access to Xcode/macOS (built in a Linux cloud sandbox),
so treat first build as "get it compiling," not "it's done." See
[Known gaps](#known-gaps--first-build-checklist) below.

## Architecture

```
Hold hotkey ──▶ AudioRecorder (AVAudioEngine, 16kHz mono)
                        │
                release key
                        ▼
              WhisperKitTranscriptionService
              (on-device, Core ML + Neural Engine)
                        │
                  raw transcript
                        ▼
              ClaudeCleanupService (optional)
              (spelling/grammar/punctuation fix,
               filler-word removal — text only,
               your own Claude API key)
                        │
                  cleaned text
                        ▼
              TextInserter (clipboard + synthetic ⌘V
              into the frontmost app)
```

Everything is wired together in `Sources/App/AppDelegate.swift`, driven by
`RecordingController`, which owns a `DictationState` (`idle` /
`recording` / `transcribing` / `cleaningUp` / `inserting` / `error`) that
both the menu bar icon (`MenuBarController`) and the floating HUD
(`HUDOverlayWindow`) observe.

### Key decisions, and why

- **On-device transcription (WhisperKit)**, not a cloud speech API: private,
  free, works offline, and Apple Silicon's Neural Engine makes it fast.
  Only the *text* transcript goes to Claude for cleanup — your voice audio
  never leaves the Mac.
- **Cleanup pass via Claude (Haiku)**: tuned specifically for a dyslexic
  user — it fixes spelling/typos, grammar, and punctuation, and strips
  filler words ("um", "uh") and stammers/false starts, without rephrasing
  your actual wording or summarizing. See the system prompt in
  `Sources/Cleanup/ClaudeCleanupService.swift` if you want to adjust its
  behavior. Toggle it off in Settings any time to insert raw transcripts.
- **Clipboard + synthetic ⌘V for insertion**, not the Accessibility "set
  focused element's value" API: far more reliable across real apps (Chrome,
  Electron apps, etc.) that don't implement AX value-setting consistently.
- **Not sandboxed**: a global hotkey and inserting text into *other* apps
  are both things the App Sandbox forbids. This app is meant to be signed
  with a Developer ID and notarized for direct distribution (outside the
  Mac App Store) — same model as apps like Raycast or Rectangle.
- **XcodeGen (`project.yml`) instead of a committed `.xcodeproj`**: the
  `.xcodeproj` is generated, not hand-written or committed, so it can't drift
  out of sync with reality or get corrupted by a bad manual edit.

## First-time setup

1. **Install Xcode** (Mac App Store — or the matching Xcode *beta* from
   [developer.apple.com/download](https://developer.apple.com/download) if
   you're running a macOS beta; the App Store build targets the current
   public macOS release and may not run on a beta OS).
2. **Install XcodeGen**: `brew install xcodegen`
3. **Generate the Xcode project**:
   ```sh
   cd whispr-clone
   xcodegen generate
   open Echo.xcodeproj
   ```
4. In Xcode, select the `Echo` target → **Signing & Capabilities** → set
   your personal team so it can be signed for local runs.
5. Build & run (⌘R). On first launch, Echo will ask for **Microphone** and
   **Accessibility** permission — both required (see Settings popover, which
   also shows live permission status with direct "Grant…" buttons).

## Getting a Claude API key

The cleanup pass uses your own key, entered in the Settings popover (stored
in Keychain, never committed anywhere). Get one at
[console.anthropic.com](https://console.anthropic.com). Without a key set,
`aiCleanupEnabled` will fail closed — the pipeline falls back to inserting
the raw transcript rather than losing your dictation (see
`RecordingController.runPipeline`).

## Known gaps / first-build checklist

Things to verify/fix once this is open in an actual Xcode, since none of
this has been compiled:

- **WhisperKit's API may have moved.** `WhisperKitTranscriptionService.swift`
  targets the `WhisperKit(WhisperKitConfig)` + `transcribe(audioArray:)`
  shape from late-2025 releases. If it doesn't match, check WhisperKit's
  README — the fix should be contained to that one file.
- **App icon**: `Resources/Assets.xcassets/AppIcon.appiconset` has the slot
  definitions but no actual images yet — that's the branding pass, next.
- **Model size**: defaults to `openai_whisper-base.en` (small/fast). Bump to
  `small.en` or larger in `WhisperKitTranscriptionService.init` if accuracy
  matters more than first-run download time / latency per utterance.
- **Hotkey capture UX** (`HotkeyRecorder`) is minimal — press-to-rebind
  works but there's no "press Esc to cancel" yet.
- **No history/undo** — a dictation replaces whatever's in the clipboard
  briefly then restores it, but there's no log of past transcriptions.
  Worth adding once the core loop feels good.

## Distributing to other Macs

For it to run on a *different* Mac without Gatekeeper blocking it, you'll
eventually need:
1. An Apple Developer Program membership ($99/yr) for a Developer ID
   signing certificate.
2. `xcodebuild archive` → export with Developer ID → `notarytool submit` →
   staple the ticket → zip or package as a `.dmg`.

None of that blocks local development — it's a packaging step for later.

## Next steps

1. Get it building and the raw dictation loop working end-to-end.
2. Verify the Claude cleanup pass reads right for your actual speech
   patterns — the prompt is easy to tune.
3. **Branding**: real app name, icon, and menu bar glyph (currently a
   plain SF Symbol placeholder) — once the mechanics work.
