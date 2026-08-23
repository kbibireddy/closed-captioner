//
//  ContentView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/26/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var speechService = SpeechService()
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var micController: MicController
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var p2pInbox = P2PInboxService()
    @State private var editedText = ""
    @State private var previousRecordingState: Bool = false
    @State private var shakeCooldownActive: Bool = false
    @State private var captionFlyOffset: CGFloat = 0
    @State private var captionFlyOpacity: Double = 1
    @State private var isSendingCaption = false
    
    init() {
        let speechService = SpeechService()
        _speechService = StateObject(wrappedValue: speechService)
        _micController = StateObject(wrappedValue: MicController(speechService: speechService))
    }
    
    var body: some View {
        // Touch fontChoice so changing Fonts rebuilds every AppType.display call site.
        let _ = appState.fontChoice
        ZStack {
            // Background color based on mode
            appState.colors.background
                .ignoresSafeArea()
            
            // Flash transition
            if appState.showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Layer order (back → front):
            // 1) Caption canvas
            // 2) ControlsView (top/bottom bars with banners between them)
            // 3) Modal overlays

            // Caption text canvas (behind ads and buttons)
            VStack {
                Spacer()

                if appState.showPoofAnimation {
                    Text("✨Poof!!!✨")
                        .font(AppType.display(56))
                        .tracking(-1.8)
                        .foregroundColor(appState.colors.text)
                        .opacity(appState.poofOpacity)
                } else if !speechService.currentText.isEmpty {
                    CaptionTextDisplay(text: speechService.currentText, colors: appState.colors)
                        .offset(y: captionFlyOffset)
                        .opacity(captionFlyOpacity)
                        .gesture(broadcastSwipeGesture)
                        .accessibilityHint(
                            p2pInbox.isListening
                                ? "Swipe up to send this caption to nearby Closed Captioner devices"
                                : ""
                        )
                } else if micController.isRecording {
                    Text("Listening…")
                        .font(AppType.display(40))
                        .tracking(-1.2)
                        .foregroundColor(appState.colors.muted)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1)

            // Ad presentation + button chrome (buttons always above ads)
            ControlsView(
                micController: micController,
                appState: appState,
                p2pInbox: p2pInbox,
                onClear: {
                    saveCurrentTextToHistory()
                    appState.clearScreen()
                    speechService.currentText = ""
                }
            )
            .zIndex(2)
            
            // Keyboard edit overlay - on top of everything
            if appState.showKeyboard {
                KeyboardEditView(
                    appState: appState,
                    text: $editedText,
                    onDone: {
                        // Update text and close keyboard view
                        speechService.currentText = editedText
                        appState.toggleKeyboard()
                    }
                )
                .zIndex(10)
                .onAppear {
                    // Initialize with current text when overlay appears
                    editedText = speechService.currentText
                }
            }
            
            // Settings overlay (History + Purchases)
            if appState.showSettings {
                SettingsView(
                    appState: appState,
                    historyManager: historyManager,
                    p2pInbox: p2pInbox
                )
                .zIndex(10)
            }
        }
        .preferredColorScheme(appState.preferredColorScheme)
        .onChange(of: micController.isRecording) { newValue in
            // When new recording starts, save current text to history
            if !previousRecordingState && newValue {
                // New recording is starting - save previous text
                saveCurrentTextToHistory()
            }
            // When recording stops, count toward interstitial cadence
            if previousRecordingState && !newValue {
                let allowPresent = !appState.showSettings
                    && !appState.showKeyboard
                    && !PremiumManager.shared.isPremium
                InterstitialCoordinator.shared.recordMicStop(allowPresent: allowPresent)
            }
            // Update previous state to track transitions
            previousRecordingState = newValue
        }
        .onAppear {
            p2pInbox.relayEnabled = appState.relayMessages
            p2pInbox.applyAutoStopAfter(appState.radioKeepAlive.duration)
            setupAudioSession()
            requestPermissions()
            previousRecordingState = micController.isRecording
            updateShakeMonitoring()
        }
        .onChange(of: appState.relayMessages) { enabled in
            p2pInbox.relayEnabled = enabled
        }
        .onChange(of: appState.radioKeepAlive) { keepAlive in
            p2pInbox.applyAutoStopAfter(keepAlive.duration)
        }
        .onChange(of: appState.showSettings) { _ in
            updateShakeMonitoring()
        }
        .onChange(of: appState.showKeyboard) { _ in
            updateShakeMonitoring()
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhase(phase)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            scheduleMeshNoticeIfListening()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            p2pInbox.prepareForBackground()
            scheduleMeshNoticeIfListening()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            cancelMeshNoticeIfForeground()
        }
        .onShake {
            handleShake()
        }
        .onDisappear {
            saveCurrentTextToHistory()
            speechService.stopRecording()
            ShakeDetectionService.shared.stopMonitoring()
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            cancelMeshNoticeIfForeground()
            p2pInbox.rebuildSessionIfListening()
        case .inactive, .background:
            scheduleMeshNoticeIfListening()
            if phase == .background {
                p2pInbox.prepareForBackground()
            }
        default:
            break
        }
        updateShakeMonitoring()
    }

    private func scheduleMeshNoticeIfListening() {
        guard p2pInbox.isListening else { return }
        NearbyMeshNotice.postStillOnMesh(keepAlive: appState.radioKeepAlive)
    }

    private func cancelMeshNoticeIfForeground() {
        guard UIApplication.shared.applicationState == .active else { return }
        NearbyMeshNotice.cancelPending()
    }

    /// Accelerometer runs only in the foreground on the caption canvas.
    private func updateShakeMonitoring() {
        let shouldRun = scenePhase == .active
            && !appState.showSettings
            && !appState.showKeyboard
        if shouldRun {
            ShakeDetectionService.shared.startMonitoring()
        } else {
            ShakeDetectionService.shared.stopMonitoring()
        }
    }

    /// Sets up the audio session for recording
    private func setupAudioSession() {
        do {
            try AudioService.shared.setupAudioSession()
        } catch {
            AppLog.debug("[ContentView] ERROR: Failed to setup audio session: \(error)")
        }
    }
    
    /// Requests microphone, speech recognition, and notification permissions
    private func requestPermissions() {
        NearbyMeshNotice.requestPermissionIfNeeded()
        AudioService.shared.requestMicrophonePermission { allowed in
            if allowed {
                DispatchQueue.main.async {
                    self.speechService.requestAuthorization { authorized in
                        if !authorized {
                            AppLog.debug("[ContentView] ERROR: Speech permission denied")
                        }
                    }
                }
            } else {
                AppLog.debug("[ContentView] ERROR: Microphone permission denied")
            }
        }
    }
    
    private var broadcastSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                handleBroadcastSwipe(translation: value.translation)
            }
    }

    private var canBroadcastCaption: Bool {
        p2pInbox.isListening
            && !speechService.currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !appState.showSettings
            && !appState.showKeyboard
            && !appState.showPoofAnimation
            && !isSendingCaption
    }

    /// Swipe up while radio is on: send nearby, keep history, fly the caption off-screen.
    private func handleBroadcastSwipe(translation: CGSize) {
        guard canBroadcastCaption else { return }
        let isUp = translation.height < -56 && abs(translation.height) > abs(translation.width)
        guard isUp else { return }
        sendCaptionNearby()
    }

    private func sendCaptionNearby() {
        let text = speechService.currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSendingCaption = true
        let sent = p2pInbox.broadcast(text, from: appState.displayName)
        guard sent else {
            isSendingCaption = false
            return
        }
        if micController.isRecording {
            micController.stopRecording()
        }

        saveCurrentTextToHistory()

        let travel = UIScreen.main.bounds.height * 0.75
        withAnimation(.easeIn(duration: 0.42)) {
            captionFlyOffset = -travel
            captionFlyOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            speechService.currentText = ""
            captionFlyOffset = 0
            captionFlyOpacity = 1
            isSendingCaption = false
        }
    }

    /// Saves the current text to history if it's valid and different from the last saved caption
    private func saveCurrentTextToHistory() {
        let text = speechService.currentText
        guard !text.isEmpty else { return }
        
        // Check if it's different from the last saved caption
        let lastCaption = historyManager.sortedCaptions.first
        guard lastCaption?.text != text else { return }
        
        let caption = CaptionText(text: text, timestamp: Date(), hasEmojis: true)
        _ = historyManager.addCaption(caption) // Guard rails are checked inside
    }
    
    /// Handles shake gesture to replace text with a pickup line
    /// Feature only available when mic is off, not in keyboard/history views, and cooldown is not active
    private func handleShake() {
        // Feature only available when:
        // - Mic is off
        // - In main content view (not keyboard/history views)
        // - Cooldown is not active
        guard !micController.isRecording,
              !appState.showKeyboard,
              !appState.showSettings,
              !shakeCooldownActive else {
            return
        }
        
        // Enable cooldown immediately to prevent multiple triggers
        shakeCooldownActive = true
        
        // Get shake strength from recently collected motion data
        let shakeStrength = ShakeDetectionService.shared.getShakeStrength()
        
        // Save current text to history before replacing
        if !speechService.currentText.isEmpty {
            saveCurrentTextToHistory()
        }
        
        // Get pickup line based on shake strength
        if let pickupLine = PickupLineService.shared.getPickupLine(shakeStrength: shakeStrength) {
            // Replace current text with pickup line
            speechService.currentText = pickupLine
            
            // Save pickup line to history
            let caption = CaptionText(text: pickupLine, timestamp: Date(), hasEmojis: false)
            _ = historyManager.addCaption(caption)
        }
        
        // Enable 5 second cooldown to prevent rapid successive triggers
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            shakeCooldownActive = false
        }
    }
}

// Extension to detect shake gesture
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetectionModifier(action: action))
    }
}

struct ShakeDetectionModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
