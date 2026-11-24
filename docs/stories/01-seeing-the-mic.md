# Seeing the mic

## 001 — Choose the mic

**Summary**: Every mic is a button; a number key switches; the choice is remembered and comes back when re-plugged.
**Status**: Done (06c69ad, cb62d8a fallback on a mic that will not open; selftest: mic list and `--mic MacBook`;
switching by key: run, Igor). The choice, the fallback, the re-plug and `--mic` are host tests since the
humble/mic-controller branch (`MicControllerTests`); the selftest still opens a real mic.
**Why**: "Mic selection is hard to change" (the Python app's dropdown).

**Use Case**: As Igor, I want to switch mics with one key, so that I can compare them while I talk.

**Acceptance Criteria**

- Scenario: Switch by key
  - Given the app shows mics numbered 1 to 5
  - When I press 3
  - Then the third mic opens and is highlighted, and the readings reset
- Scenario: The USB mic comes back
  - Given I chose the USB mic and it was unplugged, so the app fell back to the built-in mic
  - When the USB mic is plugged back in
  - Then the app reopens the USB mic by itself
- Scenario: Never AirPods by accident
  - Given no mic was chosen and no USB mic is present
  - When the app starts
  - Then it opens the built-in mic, not a Bluetooth headset

**Notes**: Opening an AirPods mic switches them to call-quality mode, which ruins music playing through them.
Bluetooth mics carry a tooltip saying so. Core Audio's private `CADefaultDeviceAggregate` devices are hidden.

## 002 — Live readings

**Summary**: Waveform, log-frequency spectrum with peak hold, 0–8 kHz spectrogram, RMS/peak meter, dominant
frequency, pitch as a note, clip count, a gain hint, and a noise readout: floor, speech level and their separation
with a good / ok / poor band, H for what they mean.
**Status**: Done (06c69ad; host tests for levels, noise floor, spectrum calibration, pitch, spectrogram; selftest log).
Noise readout and H: in progress (9680129; host tests run on Linux, the Mac app cross-compiled, iOS type-checked;
on the Mac, 2026-11-24: just test, lint, and the selftest on the OBSBOT mic logged the readout, floor -70, speech
-67, "no speech heard" in a quiet room; the band moving as someone talks and stops, and H opening, owed to a run)

**Use Case**: As Igor, I want to see my mic's level, noise and tone at a glance, so that I can set the gain and
spot hum or hiss.

**Acceptance Criteria**

- Scenario: A quiet mic still shows a waveform
  - Given the mic peaks at -30 dBFS
  - When I look at the waveform
  - Then it is scaled to its own peak and fills the panel, with the scale printed
- Scenario: Gain hint
  - Given my voice peaks under -30 dBFS
  - When I look at the status line
  - Then it says "too quiet — turn gain up"; over -3 dBFS held, "hot — back off gain"
- Scenario: Pitch of a quiet voice
  - Given I hum at 110 Hz at -50 dBFS
  - When I look at the status line
  - Then pitch reads A2

- Scenario: How much background noise is there
  - Given I talked for the last 20 s over a room whose gaps read -62 dBFS and my voice's loud frames -17 dBFS
  - When I look at the noise readout
  - Then it says noise floor -62 dB, speech -17 dB, speech − floor 45 dB GOOD
- Scenario: Nobody is talking
  - Given the last 20 s were a steady room and no speech
  - When I look at the noise readout
  - Then the separation says "no speech heard", not POOR
- Scenario: What do these mean
  - Given the noise readout is on screen
  - When I press H
  - Then the noise explainer (docs/noise.html, bundled in the Mac app) opens in the browser

**Notes**: Spectrum is amplitude dBFS (a full-scale sine reads 0 dB). Pitch: FFT autocorrelation, the strongest local
maximum over 60–1000 Hz, gate -60 dBFS. Noise readout (`AudioCore/NoiseMetrics.swift`): the last 20 s of RMS
readings (the replay's span, 600 at 30 Hz), digital silence ignored; floor = 10th percentile, speech = 95th,
separation = speech − floor, banded GOOD ≥ 30 dB, OK ≥ 15, POOR ≥ 6, under 6 "no speech heard" (a rule of thumb,
explained in docs/noise.html). The floor's window was 5 s until the readout (a running minimum before that latched
onto start-up buffers at -110 dB). Noise readout: host tests for the percentiles and bands, Linux-run; the app layer
cross-compiled for macOS and type-checked for iOS from Linux; selftest and a live run still owed on a Mac.
