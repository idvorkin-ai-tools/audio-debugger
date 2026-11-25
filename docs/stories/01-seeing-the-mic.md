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

**Summary**: Waveform, log-frequency spectrum with peak hold, 0–8 kHz spectrogram, RMS/peak meter, noise floor,
dominant frequency, pitch as a note, clip count, and a gain hint.
**Status**: Done (06c69ad; host tests for levels, noise floor, spectrum calibration, pitch, spectrogram; selftest log)

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

**Notes**: Spectrum is amplitude dBFS (a full-scale sine reads 0 dB). Pitch: FFT autocorrelation, the strongest local
maximum over 60–1000 Hz, gate -60 dBFS. Noise floor: the 10th percentile of the
last 5 s of RMS readings, digital silence ignored (a running minimum latched onto start-up buffers at -110 dB).
The spectrogram's axis is 0–8 kHz whatever the rate; what a slower input cannot carry stays black (story 015).

## 015 — See the input's rate and why the top is empty

**Summary**: Under the mic bar, one line names the input the audio really comes from, the rate it opened at, and
whether it is a Bluetooth headset in call mode, with the highest frequency that rate can carry (half the rate, the
Nyquist limit). The spectrum marks that limit at its right edge, and the spectrogram, always 0–8 kHz, stays black
above it, with a line at the limit.
**Status**: Done (013efc2; host tests for the line's text, kHz and the padded spectrogram column at 8, 16 and
48 kHz; selftest: "Input MacBook Pro Microphone · 48 kHz · up to 24 kHz" logged and on screen with "Nyquist 24k";
`just ios-build`). Call mode, 8 and 16 kHz routes and the route-change refresh: phone, not yet verified.
**Issues**: idvorkin/audio-debugger#10
**Why**: The rate was only in the log. A headset in call mode opens at 16 kHz (nothing above 8 kHz) or 8 kHz
(nothing above 4 kHz), and on screen that looked like a dull mic rather than a capped one.

**Use Case**: As Igor, I want to see the rate my mic opened at and whether my headset is in call mode, so that a
spectrum that stops at 4 or 8 kHz reads as the route's limit, not the mic's sound.

**Acceptance Criteria**

- Scenario: A full-rate mic
  - Given the built-in or a USB mic opened at 48 kHz
  - When I look under the mic bar
  - Then it reads "Input <its name> · 48 kHz · up to 24 kHz", and the spectrum's right edge is marked "Nyquist 24k"
- Scenario: A headset in call mode
  - Given AirPods' mic opened in call mode at 16 kHz
  - When I look under the mic bar
  - Then it reads "Input AirPods · 16 kHz call mode (HFP) · up to 8 kHz" in amber, and the spectrum ends at 8 kHz
- Scenario: A narrowband route leaves the top of the spectrogram black
  - Given a route opened at 8 kHz
  - When I look at the spectrogram
  - Then it is black above 4 kHz, with a line marked "Nyquist 4k", and its 2k, 4k and 6k marks stay where they are
- Scenario: The route changes under the open mic (iPhone and iPad)
  - Given a mic is open
  - When the audio route changes (a headset connects, a car takes the call link)
  - Then the line names the route's input as it now stands, and a new rate shows once the mic reopens at it
- Scenario: No mic open
  - Given the mic failed to open, or none is open
  - When I look under the mic bar
  - Then the line reads "Input —", never the last mic's rate

**Notes**: The rate shown is the one the readings are computed at, so the line, the spectrum's edge and the
spectrogram's black band always agree. On the Mac, call mode is a Bluetooth mic being open (opening it is what
switches the headset); on the phone it is the route's input being a hands-free (HFP) Bluetooth port. Before this
story the spectrogram stretched a narrowband route's 0–4 kHz over its whole height, so the top was never black and
its marks were wrong. Each change is logged as `input_format` with the line's text.
