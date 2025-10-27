# ClosedCaptioner

A beautiful iOS app for real-time speech-to-text with closed captioning capabilities.

## Features

- 🎤 **Real-time Speech Recognition**: Press and hold the mic button to speak and get instant text transcription
- 🌓 **Three Display Modes**: 
  - **Day Mode**: White background, black text
  - **Night Mode**: Black background, white text (default)
  - **Discreet Mode**: Low-contrast for privacy
- ⌨️ **Text Editor**: Full keyboard support to edit transcribed text
- ✨ **Smart Emojis**: Automatic emoji detection based on text content using Natural Language framework
- 🎨 **Beautiful UI**: Large, bold text optimized for readability in landscape mode
- 🗑️ **Quick Erase**: Tap erase button for quick screen clearing with "POOF" animation

## Controls (Landscape Mode)

- **Top Left**: Keyboard toggle
- **Top Right**: Display mode selector (Day/Night/Discreet)
- **Bottom Left**: Microphone (press and hold to record)
- **Bottom Right**: Erase/Clear screen

## Setup

1. Open the project in Xcode
2. Build and run on an iOS device
3. Grant microphone and speech recognition permissions when prompted
4. Rotate device to landscape mode

## Requirements

- iOS 16.4+
- iPhone or iPad
- Microphone access
- Speech recognition access

## Technology Stack

- SwiftUI
- AVFoundation for audio processing
- Speech framework for speech recognition
- NaturalLanguage framework for intelligent emoji detection

## License

MIT

