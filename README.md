# ClosedCaptioner

A beautiful iOS app for real-time speech-to-text with closed captioning capabilities.

## Features

- 🎤 **Real-time Speech Recognition**: Tap the mic button to speak and get instant text transcription (auto-stops after 15 seconds)
- 🌓 **Three Display Modes**: 
  - **Day Mode**: White background, black text
  - **Night Mode**: Black background, white text (default)
  - **Discreet Mode**: Low-contrast for privacy
- ⌨️ **Text Editor**: Full keyboard support to edit transcribed text
- ✨ **Smart Emojis**: Automatic emoji detection based on text content using Natural Language framework
- 🎨 **Beautiful UI**: Large, bold text optimized for readability in portrait mode
- 🗑️ **Quick Erase**: Tap erase button for quick screen clearing with "✨Poof!!!✨" animation
- 📝 **Caption History**: Track and recall previous captions with timestamps
- 💾 **Export Functionality**: Export captions to text, PDF, HTML (available via ExportManager)
- 🎲 **Shake for Fun**: Shake device to replace text with pickup lines (when mic is off)

## Controls (Portrait Mode)

- **Top Left**: History button
- **Top Right**: Display mode selector (Day/Night/Discreet)
- **Bottom Left**: Keyboard toggle
- **Bottom Center**: Microphone (tap to start recording, tap again to stop; auto-stops after 15 seconds)
- **Bottom Right**: Erase/Clear screen

## Architecture

The app follows MVVM (Model-View-ViewModel) architecture for scalability and maintainability:

```
ClosedCaptioner/
├── Models/              # Data models
│   ├── ColorMode.swift
│   └── CaptionText.swift
├── Services/            # Business logic
│   ├── AudioService.swift
│   ├── SpeechService.swift
│   ├── EmojiService.swift
│   ├── PickupLineService.swift
│   └── ShakeDetectionService.swift
├── ViewModels/          # UI state management
│   └── AppStateViewModel.swift
├── Views/               # UI components
│   ├── ContentView.swift
│   ├── CaptionTextDisplay.swift
│   ├── ControlsView.swift
│   ├── HistoryView.swift
│   ├── KeyboardEditView.swift
│   └── DoneButton.swift
├── Controllers/         # Feature controllers
│   └── MicController.swift
├── Interfaces/          # Protocol definitions
│   └── MicControlProtocol.swift
├── Managers/           # Feature managers
│   ├── HistoryManager.swift
│   └── ExportManager.swift
└── Assets.xcassets/     # Images and colors
```

## Future Features (Architecture Ready)

- 🌍 **Multi-language Support**: Support for multiple languages
- ⚙️ **Customization**: Font sizes, colors, display options
- 📊 **Analytics**: Track transcription accuracy and usage

## Setup

1. Open the project in Xcode
2. Build and run on an iOS device
3. Grant microphone and speech recognition permissions when prompted
4. App runs in portrait mode (optimized for vertical viewing)

## Requirements

- iOS 16.4+
- iPhone or iPad
- Microphone access
- Speech recognition access

## Technology Stack

- **SwiftUI** - Modern declarative UI framework
- **AVFoundation** - Audio processing and microphone access
- **Speech** - Speech recognition framework
- **NaturalLanguage** - Intelligent emoji detection and sentiment analysis
- **CoreMotion** - Accelerometer data for shake detection
- **MVVM Architecture** - Clean, testable, maintainable code

## Development

The codebase is organized for:
- Easy feature additions
- Unit testing
- Code reusability
- Scalability

## License

MIT

