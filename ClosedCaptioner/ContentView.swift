//
//  ContentView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/26/25.
//

import SwiftUI
import Speech
import AVFoundation
import NaturalLanguage

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var colorMode: ColorMode = .night // Default is night mode
    @State private var showKeyboard = false
    @State private var editedText = ""
    @State private var showFlash = false
    @State private var showPoofAnimation = false
    @State private var poofOpacity: Double = 1.0
    
    enum ColorMode: String, CaseIterable {
        case day
        case night
        case discreet
        
        var background: Color {
            switch self {
            case .day:
                return .white
            case .night:
                return .black
            case .discreet:
                return Color(red: 0.1, green: 0.1, blue: 0.1) // Very dark gray
            }
        }
        
        var text: Color {
            switch self {
            case .day:
                return .black
            case .night:
                return .white
            case .discreet:
                return Color(red: 0.2, green: 0.2, blue: 0.2) // Slightly lighter gray - very low contrast
            }
        }
        
        var icon: String {
            switch self {
            case .day:
                return "sun.max.fill"
            case .night:
                return "moon.fill"
            case .discreet:
                return "eye.slash.fill"
            }
        }
        
        var buttonBackground: Color {
            switch self {
            case .day:
                return Color.gray.opacity(0.3)
            case .night:
                return Color.gray.opacity(0.3)
            case .discreet:
                return Color.gray.opacity(0.5)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background color based on mode
            colorMode.background
                .ignoresSafeArea()
            
            // Flash transition
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Main content
            ZStack {
                // Top buttons
                VStack {
                    HStack {
                        // Top left: Keyboard button
                        Button(action: toggleKeyboard) {
                            Image(systemName: "keyboard")
                                .font(.title2)
                                .foregroundColor(colorMode.text)
                                .padding()
                                .background(
                                    showKeyboard 
                                        ? Color.blue.opacity(0.5)
                                        : colorMode.buttonBackground
                                )
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Top right: Display mode picker
                        Picker("Color Mode", selection: $colorMode) {
                            ForEach(ColorMode.allCases, id: \.self) { mode in
                                Image(systemName: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                        .tint(colorMode.text.opacity(0.3))
                        .colorMultiply(colorMode.text)
                    }
                    .padding()
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(2)
                
                // Bottom buttons
                VStack {
                    Spacer()
                    
                    HStack {
                        // Bottom left: Mic button
                        Button(action: {
                            if !speechRecognizer.isRecording {
                                // Start recording
                                speechRecognizer.isRecording = true
                                startRecording()
                            } else {
                                // Stop recording
                                speechRecognizer.isRecording = false
                                stopRecording()
                            }
                        }) {
                            Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                                .font(.title)
                                .foregroundColor(colorMode.text)
                                .padding()
                                .background(
                                    speechRecognizer.isRecording 
                                        ? Color.red.opacity(0.7)
                                        : colorMode.buttonBackground
                                )
                                .clipShape(Circle())
                        }
                        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: 0) {
                            // Empty handler for tap detection
                        } onPressingChanged: { pressing in
                            if pressing {
                                // Finger down
                                if !speechRecognizer.isRecording {
                                    speechRecognizer.isRecording = true
                                    startRecording()
                                }
                            } else {
                                // Finger up
                                if speechRecognizer.isRecording {
                                    speechRecognizer.isRecording = false
                                    stopRecording()
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Bottom right: Erase button
                        Button(action: clearScreen) {
                            Image(systemName: "eraser.fill")
                                .font(.title)
                                .foregroundColor(colorMode.text)
                                .padding()
                                .background(colorMode.buttonBackground)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(2)
                
                // Text display or editor (center)
                VStack {
                    Spacer()
                    
                    if showKeyboard {
                        ZStack {
                            // Background - tapable to close
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleKeyboard()
                                }
                            
                            TextEditor(text: $editedText)
                                .font(.system(size: 36, weight: .bold, design: .default))
                                .foregroundColor(colorMode.text)
                                .scrollContentBackground(.hidden)
                                .frame(height: 200)
                                .padding()
                                .background(colorMode.background)
                                .onTapGesture {
                                    // Prevent closing when tapping editor
                                }
                        }
                    } else if showPoofAnimation {
                        // Show POOF animation
                        Text("✨Poof!!!✨")
                            .font(.system(size: 80, weight: .black, design: .default))
                            .foregroundColor(colorMode.text)
                            .opacity(poofOpacity)
                    } else {
                        // Only show text if there's actual content
                        if !speechRecognizer.currentText.isEmpty {
                            Text(speechRecognizer.currentText)
                                .font(.system(size: calculateFontSize(), weight: .black, design: .default))
                                .foregroundColor(colorMode.text)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .frame(maxWidth: .infinity)
                                .minimumScaleFactor(0.3)
                                .lineSpacing(8)
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1)
            }
        }
        .onAppear {
            setupAudioSession()
            requestPermissions()
        }
        .onDisappear {
            speechRecognizer.stopRecognition()
        }
    }
    
    
    private func toggleKeyboard() {
        if !showKeyboard {
            // Opening keyboard - load current text
            editedText = speechRecognizer.currentText
            showKeyboard = true
        } else {
            // Closing keyboard - save edited text
            speechRecognizer.currentText = editedText
            showKeyboard = false
        }
    }
    
    private func calculateFontSize() -> CGFloat {
        let baseSize: CGFloat = 80 // Large size for 4-6 words in landscape
        let textLength = speechRecognizer.currentText.count
        
        // Reduce size proportionally as text gets longer
        if textLength <= 30 {
            return baseSize
        } else if textLength <= 60 {
            return baseSize * 0.8
        } else if textLength <= 100 {
            return baseSize * 0.65
        } else if textLength <= 150 {
            return baseSize * 0.5
        } else {
            return baseSize * 0.4
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use playAndRecord to allow defaultToSpeaker option
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            if allowed {
                DispatchQueue.main.async {
                    speechRecognizer.requestAuthorization { authorized in
                        if !authorized {
                            print("Speech permission denied")
                        }
                    }
                }
            } else {
                print("Microphone permission denied")
            }
        }
    }
    
    private func startRecording() {
        speechRecognizer.startRecording()
    }
    
    private func stopRecording() {
        speechRecognizer.stopRecording()
    }
    
    private func clearScreen() {
        // Flash effect - white screen flash
        showFlash = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            showFlash = false
            speechRecognizer.currentText = ""
            
            // Start POOF animation
            startPoofAnimation()
        }
    }
    
    private func startPoofAnimation() {
        showPoofAnimation = true
        poofOpacity = 1.0
        
        // Animate POOF disappearing over 0.8 seconds (much faster)
        withAnimation(.easeOut(duration: 0.8)) {
            poofOpacity = 0.0
        }
        
        // After animation completes, hide it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            showPoofAnimation = false
            poofOpacity = 1.0
        }
    }
    
    private func stopPoofAnimation() {
        // Stop the animation immediately
        showPoofAnimation = false
        poofOpacity = 1.0
        speechRecognizer.currentText = ""
    }
    
    private let audioSession = AVAudioSession.sharedInstance()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Speech Recognizer with Volume Button Control
class SpeechRecognizer: ObservableObject {
    @Published var currentText: String = ""
    @Published var isRecording: Bool = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var inputNode: AVAudioInputNode?
    
    // Track if text is from speech recognition (for emoji logic)
    private var textIsFromSpeech: Bool = false
    private var lastRecordedText: String = ""
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
    
    func startRecording() {
        startRecognition()
    }
    
    func stopRecording() {
        stopRecognition()
    }
    
    private func startRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }
        
        // Stop any existing recognition
        stopRecognition()
        
        // Create new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            inputNode?.removeTap(onBus: 0)
        }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine could not start: \(error)")
            return
        }
        
        // Mark that upcoming text is from speech
        textIsFromSpeech = true
        lastRecordedText = ""
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    let newText = result.bestTranscription.formattedString
                    self.currentText = newText
                    self.lastRecordedText = newText
                }
            }
            
            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRecognition() {
        recognitionTask?.finish()
        recognitionRequest?.endAudio()
        
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        
        // Always add emojis if text came from speech recognition
        if textIsFromSpeech && !currentText.isEmpty {
            // Add emojis to the speech-text
            addEmojisToText()
            textIsFromSpeech = false
        }
        
        recognitionRequest = nil
        recognitionTask = nil
        inputNode = nil
    }
    
    private func addEmojisToText() {
        // Check if emojis are already added to current text
        if currentText.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
            return
        }
        
        // Perform emoji analysis on background thread for better performance
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let emojis = self.analyzeTextForEmojis(text: self.currentText)
            
            DispatchQueue.main.async {
                if !emojis.isEmpty {
                    self.currentText = self.currentText + " " + emojis
                } else {
                    // Final fallback - always add at least one emoji
                    self.currentText = self.currentText + " " + "💭"
                }
            }
        }
    }
    
    private func analyzeTextForEmojis(text: String) -> String {
        // Use Natural Language framework for intelligent emoji selection
        let emojis = getEmojisForText(text)
        return emojis
    }
    
    private func getEmojisForText(_ text: String) -> String {
        // Use Natural Language framework for sentiment analysis
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        // Get sentiment scores
        var sentiment: String = ""
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let tag = tag {
                sentiment = tag.rawValue
            }
            return true
        }
        
        let bestEmojis = selectEmojisBasedOnContent(text: text, sentiment: sentiment)
        
        return bestEmojis
    }
    
    private func selectEmojisBasedOnContent(text: String, sentiment: String) -> String {
        var emojis: Set<String> = []
        
        // Comprehensive emoji mapping based on semantic meaning
        let emojiMap: [String: Set<String>] = [
            // Greetings & Social
            "hello": ["👋", "🙋"],
            "hi": ["👋", "🙋"],
            "thanks": ["🙏", "😊"],
            "thank": ["🙏", "😊"],
            "bye": ["👋", "👋🏻"],
            "goodbye": ["👋", "👋🏻"],
            
            // Emotions - Positive
            "happy": ["😊", "😄", "😃"],
            "great": ["👍", "😊"],
            "good": ["👍", "✅"],
            "excellent": ["⭐️", "🌟"],
            "wonderful": ["✨", "😊"],
            "amazing": ["🤩", "😍"],
            "love": ["❤️", "🥰"],
            "beautiful": ["💐", "🌟"],
            "nice": ["😊", "👍"],
            "yes": ["✅", "👍"],
            
            // Emotions - Negative
            "sad": ["😢", "😔"],
            "bad": ["😞", "😟"],
            "terrible": ["😨", "😰"],
            "awful": ["😞", "😕"],
            "hate": ["😠", "🤬"],
            "no": ["❌", "😐"],
            
            // Emotions - Complex
            "excited": ["🤩", "🥳"],
            "surprised": ["😲", "😮"],
            "worried": ["😟", "😰"],
            "angry": ["😠", "🤬"],
            
            // Activities
            "work": ["💼", "⌚️"],
            "study": ["📚", "📖"],
            "play": ["🎮", "🎯"],
            "exercise": ["🏋️", "🏃"],
            "run": ["🏃", "🏃‍♀️"],
            "walk": ["🚶", "🚶‍♀️"],
            
            // Food & Drink
            "eat": ["🍽️", "🍴"],
            "food": ["🍔", "🍕"],
            "breakfast": ["🍳", "🥞"],
            "lunch": ["🥙", "🍲"],
            "dinner": ["🍽️", "🍖"],
            "coffee": ["☕️", "☕"],
            "drink": ["🥤", "🍹"],
            
            // Weather
            "sunny": ["☀️", "🌞"],
            "rain": ["🌧️", "☔️"],
            "snow": ["❄️", "⛄️"],
            "cloud": ["☁️", "🌥️"],
            "hot": ["🔥", "🌡️"],
            "cold": ["🥶", "❄️"],
            
            // Technology
            "phone": ["📱", "📲"],
            "computer": ["💻", "🖥️"],
            "app": ["📱", "⚙️"],
            "internet": ["🌐", "📡"],
            "wifi": ["📶", "📡"],
            
            // Time
            "morning": ["🌅", "🌄"],
            "afternoon": ["🌆", "🏙️"],
            "evening": ["🌆", "🌃"],
            "night": ["🌙", "🌃"],
            
            // Questions
            "how": ["❓", "🤔"],
            "what": ["❓", "🤔"],
            "where": ["❓", "🗺️"],
            "why": ["❓", "🤔"],
            
            // People & Relationships
            "friend": ["👫", "🤝"],
            "family": ["👨‍👩‍👧‍👦", "👪"],
            "home": ["🏠", "🏡"],
            "help": ["🆘", "🙋‍♂️"]
        ]
        
        let lowercased = text.lowercased()
        
        // Find matching emojis based on content
        for (keyword, emojiSet) in emojiMap {
            if lowercased.contains(keyword) {
                emojis.formUnion(emojiSet)
            }
        }
        
        // Sentiment-based fallback if no matches found
        if emojis.isEmpty {
            let sentimentScore = Double(sentiment) ?? 0.0
            if sentimentScore > 0.3 {
                emojis.insert("😊")
            } else if sentimentScore < -0.3 {
                emojis.insert("😔")
            } else {
                // Random neutral emoji fallback
                let neutralEmojis = ["💬", "💭", "✨", "🌟", "⭐", "📝", "🔤", "💡", "📋", "🎯"]
                if let randomEmoji = neutralEmojis.randomElement() {
                    emojis.insert(randomEmoji)
                } else {
                    emojis.insert("💭") // Final fallback
                }
            }
        }
        
        // Always return at least 1 emoji, up to 3 emojis (limit to best matches)
        let emojiArray = Array(emojis.prefix(3))
        return emojiArray.joined(separator: " ")
    }
    
}
