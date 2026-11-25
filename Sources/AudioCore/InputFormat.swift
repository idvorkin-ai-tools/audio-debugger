import Foundation

/// What the live readings are computed from (story 015): the input the route really uses, the rate it opened at, and
/// whether it is a Bluetooth headset in call (hands-free) mode, which is what caps the rate at 16 or 8 kHz.
public struct InputFormat: Equatable, Sendable {
    public let name: String
    public let rate: Double
    public let callMode: Bool

    public init(name: String, rate: Double, callMode: Bool) {
        self.name = name
        self.rate = rate
        self.callMode = callMode
    }

    /// The highest frequency the rate can carry: nothing above it reaches the spectrum.
    public var nyquist: Double { rate / 2 }

    /// The line under the mic bar: "Input AirPods · 16 kHz call mode (HFP) · up to 8 kHz".
    public var text: String {
        "Input \(name) · \(kiloHertz(rate)) kHz\(callMode ? " call mode (HFP)" : "") · up to \(kiloHertz(nyquist)) kHz"
    }

    /// The line while no mic is open: never the last mic's rate.
    public static let noneText = "Input —"
}

/// A frequency in kHz, as short as it reads exactly: 48000 → "48", 44100 → "44.1", 22050 → "22.05".
public func kiloHertz(_ hz: Double) -> String {
    var s = String(format: "%.2f", hz / 1000)
    while s.hasSuffix("0") { s.removeLast() }
    if s.hasSuffix(".") { s.removeLast() }
    return s
}

/// One spectrogram column on a fixed 0…`topHz` axis: the bins of `db` (bin k at (k + 1) · `binHz`, as
/// `SpectrumAnalyzer.frequencies`) up to `topHz`, padded with `floorDB` where the rate's Nyquist limit falls below
/// it. Without the padding, an 8 kHz route's 0–4 kHz would be stretched over the whole axis.
public func spectrogramColumn(_ db: [Float], binHz: Float, topHz: Float = 8000, floorDB: Float = -200) -> [Float] {
    guard binHz > 0 else { return [] }
    let bins = Int(topHz / binHz)
    let real = db.prefix(min(db.count, bins))
    return Array(real) + [Float](repeating: floorDB, count: bins - real.count)
}
