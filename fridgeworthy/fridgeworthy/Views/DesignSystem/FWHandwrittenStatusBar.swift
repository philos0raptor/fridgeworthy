import SwiftUI
import UIKit

struct FWHandwrittenStatusBar: View {
    let inkColor: Color
    let verticalOffset: CGFloat
    @State private var batteryLevel: Float = -1

    init(inkColor: Color = FW.Color.ink, verticalOffset: CGFloat = -52) {
        self.inkColor = inkColor
        self.verticalOffset = verticalOffset
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let snapshot = SystemStatusSnapshot(
                date: context.date,
                batteryLevel: batteryLevel
            )

            HStack(spacing: 12) {
                FWHandwrittenGlyphSequence(text: snapshot.timeGlyphs, inkColor: inkColor)
                    .frame(width: 88, alignment: .leading)
                    .scaleEffect(0.7, anchor: .leading)

                Spacer()

                Group {
                    if let batteryGlyphs = snapshot.batteryGlyphs {
                        FWHandwrittenGlyphSequence(text: batteryGlyphs, inkColor: inkColor)
                    } else {
                        Text("—%")
                            .font(FW.Font.caption(16, weight: .bold))
                            .foregroundStyle(inkColor)
                    }
                }
                .frame(width: 88, alignment: .trailing)
                .scaleEffect(0.7, anchor: .trailing)
            }
            .frame(height: 34)
            .offset(y: verticalOffset)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Status")
            .accessibilityValue(snapshot.accessibilityValue)
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            batteryLevel = UIDevice.current.batteryLevel
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
            batteryLevel = UIDevice.current.batteryLevel
        }
    }
}

struct FWHandwrittenGlyphSequence: View {
    let text: String
    var height: CGFloat = 28
    var inkColor: Color = FW.Color.ink

    var body: some View {
        HStack(spacing: -2) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                if let asset = Self.assetName(for: character) {
                    Image(asset)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(inkColor)
                        .scaleEffect(Self.scale(for: character))
                        .offset(y: Self.verticalOffset(for: character))
                        .frame(width: Self.width(for: character), height: height)
                        .clipped()
                }
            }
        }
    }

    private static func assetName(for character: Character) -> String? {
        switch character {
        case "0": "FWDigitZero"
        case "1": "FWDigitOne"
        case "2": "FWDigitTwo"
        case "3": "FWDigitThree"
        case "4": "FWDigitFour"
        case "5": "FWDigitFive"
        case "6": "FWDigitSix"
        case "7": "FWDigitSeven"
        case "8": "FWDigitEight"
        case "9": "FWDigitNine"
        case ":": "FWDigitColon"
        case "%": "FWDigitPercent"
        default: nil
        }
    }

    private static func width(for character: Character) -> CGFloat {
        switch character {
        case ":": 11
        case "1": 17
        case "%": 25
        default: 22
        }
    }

    private static func scale(for character: Character) -> CGFloat {
        switch character {
        case "0": 2.4
        case "1": 2.6
        case "2": 2.8
        case "3": 2.8
        case "4": 2.5
        case "5": 2.7
        case "6": 2.8
        case "7": 2.5
        case "8": 2.25
        case "9": 2.3
        case ":": 6.5
        case "%": 5.5
        default: 1
        }
    }

    private static func verticalOffset(for character: Character) -> CGFloat {
        switch character {
        case ":", "%": -4
        default: 0
        }
    }
}
