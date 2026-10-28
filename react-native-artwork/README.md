# Artwork carousel

This Expo app supplies a horizontally scrolling stack of portrait artwork cards and the animated memory note card inside the native artwork view. The front artwork card grows and straightens as the stack moves; neighboring cards remain visible behind it. The note card expands and straightens when its input gains focus. The host app passes image URLs and the saved note into the React Native components; they send add-photo, note-change, and focus messages back to SwiftUI.

From the repository root, run `scripts/build-artwork-carousel.sh` after cloning or changing this component. This requires Node.js, Xcode, and CocoaPods. The command creates a local Swift Package at `react-native-artwork/artifacts/FridgeworthyArtworkCarousel-release` and refreshes Xcode package resolution. The host Xcode project links this package. Generated native sources, dependencies, and build artifacts are ignored by Git.

If the Xcode project was already open before the local package was built, choose **File → Packages → Resolve Package Versions** in Xcode to refresh that window's package graph.

The animations are original code informed by the visual behavior of the Reactiive iMessage stack and dot-sheet demos; no source from those demos is copied into this project.
