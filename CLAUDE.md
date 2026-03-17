# TextReader

## Project Overview

iOS text scanning app that uses Vision (OCR) to extract text from camera or photo library. Users can scan text live or pick images, and copy results to clipboard.

## Tech Stack

- **Language:** Swift 5
- **Platform:** iOS 13+
- **Dependency Manager:** CocoaPods (`pod install` to set up)
- **Key Dependencies:** Cartography (Auto Layout DSL), Firebase Analytics
- **Frameworks:** Vision (OCR), AVFoundation (camera)
- **UI:** UIKit (programmatic layout with Cartography)
- **Testing:** XCTest
- **Ruby Tooling:** Use RVM (not rbenv) for Ruby version management

## Project Structure

- `TextReader/` — Main iOS app
  - `ViewController.swift` — Primary view controller with scanning UI
  - `Extensions/` — Swift extensions (UIView helpers)
  - `AppDelegate.swift`, `SceneDelegate.swift` — App lifecycle
- `TextReaderTests/` — Unit tests

## Development

- Open `TextReader.xcworkspace` (not `.xcodeproj`) since the project uses CocoaPods
- Run `bundle install && bundle exec pod install` to set up dependencies

## Build & Test

```bash
# Build
xcodebuild -workspace TextReader.xcworkspace -scheme TextReader -destination "platform=iOS Simulator,name=iPhone 16" build

# Test
xcodebuild -workspace TextReader.xcworkspace -scheme TextReader -destination "platform=iOS Simulator,name=iPhone 16" test
```

## Conventions

- Use gitmoji prefixes for commit messages (e.g. `✨ feat`, `🐛 fix`, `♻️ refactor`)
