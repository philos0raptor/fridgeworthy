import SwiftUI
import UIKit
import reactnativeartworkbrownfield

struct ArtworkCarouselHostView: UIViewControllerRepresentable {
    let images: [[String: String]]
    let allowsAddingPhoto: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = ReactNativeViewController(
            initialProps: [
                "images": images,
                "allowsAddingPhoto": allowsAddingPhoto,
            ]
        )
        controller.loadViewIfNeeded()
        controller.view.backgroundColor = .clear
        controller.view.isOpaque = false
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}
}

struct ArtworkNoteHostView: UIViewControllerRepresentable {
    let initialNote: String
    let sessionID: String
    let fontStyle: String

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = ReactNativeViewController(
            initialProps: [
                "mode": "note",
                "initialNote": initialNote,
                "noteSessionID": sessionID,
                "fontStyle": fontStyle,
            ]
        )
        controller.loadViewIfNeeded()
        controller.view.backgroundColor = .clear
        controller.view.isOpaque = false
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}
}
