import SwiftUI

/// Hand-drawn wavy crayon underline shape. Used under "everywhere" (SignIn) and month headings (Gallery).
struct CrayonUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h * 0.5

        path.move(to: CGPoint(x: 0, y: midY + h * 0.1))
        path.addCurve(
            to: CGPoint(x: w * 0.3, y: midY - h * 0.25),
            control1: CGPoint(x: w * 0.08, y: midY + h * 0.15),
            control2: CGPoint(x: w * 0.18, y: midY - h * 0.3)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.65, y: midY + h * 0.15),
            control1: CGPoint(x: w * 0.42, y: midY - h * 0.2),
            control2: CGPoint(x: w * 0.52, y: midY + h * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: w, y: midY - h * 0.1),
            control1: CGPoint(x: w * 0.78, y: midY + h * 0.05),
            control2: CGPoint(x: w * 0.92, y: midY - h * 0.15)
        )

        return path.strokedPath(StrokeStyle(lineWidth: h * 0.45, lineCap: .round, lineJoin: .round))
    }
}

/// Convenience view: purple crayon underline with fixed aspect ratio.
struct FWCrayonUnderline: View {
    var color: Color = FW.Color.accent
    var width: CGFloat = 120
    var height: CGFloat = 8

    var body: some View {
        CrayonUnderline()
            .fill(color.opacity(0.5))
            .frame(width: width, height: height)
    }
}
