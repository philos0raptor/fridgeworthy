import UIKit

/// The reviewed display image and the unchanged full-resolution source travel together.
struct PendingArtworkPhoto: Identifiable {
    let id = UUID()
    let preparedImage: UIImage
    let originalData: Data
}

struct ArtworkReviewItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let originalData: Data
}
