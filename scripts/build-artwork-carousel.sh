#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
carousel_dir="$repo_dir/react-native-artwork"

cd "$carousel_dir"
npm ci
npx expo prebuild --platform ios --no-install
(cd ios && pod install)
npx expo-brownfield build:ios --release --package FridgeworthyArtworkCarousel
xcodebuild \
  -project "$repo_dir/fridgeworthy/fridgeworthy.xcodeproj" \
  -scheme fridgeworthy \
  -resolvePackageDependencies
