import SwiftUI

/// Drag handles on the source photo. Coordinates match PaperCorners' top-left origin.
struct PaperCornerEditor: View {
    let image: UIImage
    @Binding var corners: PaperCorners

    var body: some View {
        GeometryReader { geometry in
            let imageSize = image.size
            let scale = min(geometry.size.width / imageSize.width, geometry.size.height / imageSize.height)
            let fitted = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            let origin = CGPoint(x: (geometry.size.width - fitted.width) / 2,
                                 y: (geometry.size.height - fitted.height) / 2)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width, height: geometry.size.height)

            Path { path in
                let points = corners.points.map {
                    CGPoint(x: origin.x + $0.x * fitted.width, y: origin.y + $0.y * fitted.height)
                }
                path.addLines(points + [points[0]])
            }
            .stroke(FW.Color.accent, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))

            ForEach(0..<4, id: \.self) { index in
                let point = corners.points[index]
                Circle()
                    .fill(FW.Color.accent)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .position(x: origin.x + point.x * fitted.width,
                              y: origin.y + point.y * fitted.height)
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("paperEditor")).onChanged { drag in
                        let x = (drag.location.x - origin.x) / fitted.width
                        let y = (drag.location.y - origin.y) / fitted.height
                        corners = corners.replacing(index, with: CGPoint(x: x, y: y))
                    })
                    .accessibilityLabel(["Top left", "Top right", "Bottom right", "Bottom left"][index] + " paper corner")
            }
        }
        .coordinateSpace(name: "paperEditor")
        .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
    }
}
