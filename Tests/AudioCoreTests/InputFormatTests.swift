import Testing

@testable import AudioCore

// Story 015: the input's rate on screen, and a spectrogram that stays black above the rate's Nyquist limit.

@Test func inputLineReadsAFullRateMic() {
    let f = InputFormat(name: "MacBook Pro Microphone", rate: 48_000, callMode: false)
    #expect(f.nyquist == 24_000)
    #expect(f.text == "Input MacBook Pro Microphone · 48 kHz · up to 24 kHz")
}

@Test func inputLineReadsACallModeHeadset() {
    let wide = InputFormat(name: "AirPods", rate: 16_000, callMode: true)
    #expect(wide.text == "Input AirPods · 16 kHz call mode (HFP) · up to 8 kHz")
    let narrow = InputFormat(name: "Car", rate: 8_000, callMode: true)
    #expect(narrow.text == "Input Car · 8 kHz call mode (HFP) · up to 4 kHz")
}

@Test func kiloHertzIsAsShortAsItReadsExactly() {
    #expect(kiloHertz(48_000) == "48")
    #expect(kiloHertz(44_100) == "44.1")
    #expect(kiloHertz(22_050) == "22.05")
    #expect(kiloHertz(8_000) == "8")
}

/// The analyzer's bins for a 4096-point FFT at `rate`, all at `db`.
private func bins(rate: Float, db: Float = -40) -> (column: [Float], binHz: Float) {
    ([Float](repeating: db, count: 4096 / 2 - 1), rate / 4096)
}

@Test func spectrogramColumnAt48kHzKeepsOnlyUpTo8kHz() {
    let (db, binHz) = bins(rate: 48_000)
    let col = spectrogramColumn(db, binHz: binHz)
    #expect(col.count == Int(8000 / binHz))
    #expect(col.allSatisfy { $0 == -40 })
}

@Test func spectrogramColumnAt16kHzFillsTheAxis() {
    let (db, binHz) = bins(rate: 16_000)
    let col = spectrogramColumn(db, binHz: binHz)
    #expect(col.count == 2048)
    // Every bin up to the 8 kHz Nyquist is real; only the one bin at 8 kHz itself is padding.
    #expect(col.prefix(2047).allSatisfy { $0 == -40 })
}

@Test func spectrogramColumnAt8kHzIsBlackAbove4kHz() {
    let (db, binHz) = bins(rate: 8_000)
    let col = spectrogramColumn(db, binHz: binHz)
    #expect(col.count == 4096)
    #expect(col.prefix(2047).allSatisfy { $0 == -40 })
    #expect(col.dropFirst(2047).allSatisfy { $0 == -200 })
    // On the 256-row spectrogram the top half (4–8 kHz) is the floor colour, the bottom half is not.
    var gram = Spectrogram(width: 1, height: 256)
    gram.push(col)
    #expect(gram.pixels[0] == Spectrogram.lut[0])
    #expect(gram.pixels[127] == Spectrogram.lut[0])
    #expect(gram.pixels[129] != Spectrogram.lut[0])
}
