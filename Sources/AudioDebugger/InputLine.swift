import AudioCore
import SwiftUI

/// Story 015: under the mic bar, the input the audio really comes from, its rate and the highest frequency that rate
/// carries; amber when a Bluetooth headset is in call mode, which is what caps it at 8 or 4 kHz.
struct InputLine: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let input = model.input
        Text(input?.text ?? InputFormat.noneText)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(input?.callMode == true ? amber : Color(white: 0.7))
            .lineLimit(2)
            .help(
                input?.callMode == true
                    ? "Call mode: the headset sends its mic at a phone-call rate, so nothing above "
                        + "\(kiloHertz(input?.nyquist ?? 0)) kHz reaches the spectrum"
                    : "The rate the mic opened at; half of it is the highest frequency the spectrum can show")
    }
}
