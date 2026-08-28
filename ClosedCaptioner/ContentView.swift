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
    @StateObject private var speechService: SpeechService
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var micController: MicController
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var p2pInbox = P2PInboxService()
    @State private var editedText = ""
    @State private var previousRecordingState: Bool = false
    @State private var shakeCooldownActive: Bool = false
    @State private var lastCaptionSource: CaptionSource = .text
    @State private var captionOffset: CGSize = .zero
    @State private var captionOpacity: Double = 1
    @State private var captionScale: CGFloat = 1
    @State private var isSendingCaption = false
    @State private var isFlickBusy = false
    @State private var radioIsOn = false
    /// Center feedback after send / failed flick (like Poof!!!).
    @State private var canvasFeedback: CanvasFeedback?
    @State private var canvasFeedbackOpacity: Double = 1

    private enum CanvasFeedback: Equatable {
        case sent
        case tryAgain
    }
    
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
            
            // Layer order (back → front):
            // 1) Caption canvas (full-area flick when radio + text)
            // 2) ControlsView (top/bottom bars with banners between them)
            // 3) Modal overlays

            captionCanvas
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
                        lastCaptionSource = .text
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
                saveCurrentTextToHistory()
                lastCaptionSource = .speech
            }
            // When recording stops, count toward interstitial cadence
            if previousRecordingState && !newValue {
                let allowPresent = !appState.showSettings
                    && !appState.showKeyboard
                    && !PremiumManager.shared.adsSuppressed
                InterstitialCoordinator.shared.recordMicStop(allowPresent: allowPresent)
            }
            // Update previous state to track transitions
            previousRecordingState = newValue
        }
        .onAppear {
            p2pInbox.relayEnabled = appState.relayMessages
            p2pInbox.applyAutoStopAfter(appState.radioKeepAlive.duration)
            speechService.emojiDetectionEnabled = appState.emojiDetectionEnabled
            radioIsOn = p2pInbox.isListening
            previousRecordingState = micController.isRecording
            updateShakeMonitoring()
            // ATT before AdMob (and before mic/speech alerts) so App Review sees tracking prompt.
            AdsBootstrap.prepareForForeground(isPremium: PremiumManager.shared.adsSuppressed) {
                requestPermissions()
            }
        }
        .onReceive(p2pInbox.chrome.$isListening) { radioIsOn = $0 }
        .onChange(of: appState.relayMessages) { enabled in
            p2pInbox.relayEnabled = enabled
        }
        .onChange(of: appState.radioKeepAlive) { keepAlive in
            p2pInbox.applyAutoStopAfter(keepAlive.duration)
        }
        .onChange(of: appState.emojiDetectionEnabled) { enabled in
            speechService.emojiDetectionEnabled = enabled
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            p2pInbox.prepareForBackground()
            NearbyMeshNotice.noteWentToBackground(
                radioOn: p2pInbox.isListening,
                keepAlive: appState.radioKeepAlive
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)) { _ in
            NearbyMeshNotice.noteDeviceLocked(
                radioOn: p2pInbox.isListening,
                keepAlive: appState.radioKeepAlive
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            NearbyMeshNotice.noteBecameActive()
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
            NearbyMeshNotice.noteBecameActive()
            p2pInbox.rebuildSessionIfListening()
        case .background:
            p2pInbox.prepareForBackground()
            NearbyMeshNotice.noteWentToBackground(
                radioOn: p2pInbox.isListening,
                keepAlive: appState.radioKeepAlive
            )
        default:
            break
        }
        updateShakeMonitoring()
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

    /// Requests microphone and speech recognition. Huddle notifications wait until radio on.
    private func requestPermissions() {
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
    
    private var captionCanvas: some View {
        VStack {
            Spacer()

            if appState.showPoofAnimation {
                Text("Poof!!!")
                    .font(AppType.display(56))
                    .tracking(-1.8)
                    .foregroundColor(appState.colors.text)
                    .opacity(appState.poofOpacity)
            } else if let canvasFeedback {
                canvasFeedbackView(canvasFeedback)
            } else if !speechService.currentText.isEmpty {
                CaptionTextDisplay(text: speechService.currentText, colors: appState.colors)
                    .offset(captionOffset)
                    .scaleEffect(captionScale)
                    .opacity(captionOpacity)
                    .accessibilityHint(
                        radioIsOn
                            ? "Flick up to send this caption to nearby Closed Captioner devices"
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
        .contentShape(Rectangle())
        .gesture(broadcastFlickGesture, including: canBroadcastCaption ? .all : .none)
    }

    @ViewBuilder
    private func canvasFeedbackView(_ feedback: CanvasFeedback) -> some View {
        switch feedback {
        case .sent:
            Text("Sent!")
                .font(AppType.display(56))
                .tracking(-1.8)
                .foregroundColor(appState.colors.text)
                .opacity(canvasFeedbackOpacity)
        case .tryAgain:
            Text("Try again, Swipe up next time")
                .font(AppType.display(28))
                .tracking(-0.8)
                .foregroundColor(appState.colors.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .opacity(canvasFeedbackOpacity)
                .accessibilityLabel("Try again, swipe up next time")
        }
    }

    /// Full-canvas drag: finger-follow, then flick in an upward 120° cone (±60° from up).
    private var broadcastFlickGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                guard canBroadcastCaption else { return }
                captionOffset = value.translation
                captionScale = 1.05
            }
            .onEnded { value in
                handleBroadcastFlick(value)
            }
    }

    private var canBroadcastCaption: Bool {
        radioIsOn
            && !speechService.currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !appState.showSettings
            && !appState.showKeyboard
            && !appState.showPoofAnimation
            && canvasFeedback == nil
            && !isSendingCaption
            && !isFlickBusy
    }

    private func handleBroadcastFlick(_ value: DragGesture.Value) {
        // Don’t re-check canBroadcastCaption here — it can race with gesture end.
        guard radioIsOn,
              !speechService.currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !isSendingCaption,
              !isFlickBusy,
              canvasFeedback == nil else {
            resetCaptionTransform(animated: true)
            return
        }

        let translation = value.translation
        let distance = hypot(translation.width, translation.height)
        // Soft cancel: tiny moves spring home without feedback.
        guard distance >= 28 else {
            resetCaptionTransform(animated: true)
            return
        }

        if isUpwardSendCone(translation: translation, predictedEnd: value.predictedEndTranslation) {
            commitSendFlick(translation: translation, predictedEnd: value.predictedEndTranslation)
        } else {
            showTryAgainAndRestore()
        }
    }

    /// Straight up ± 60° (total 120° cone). Prefers flick impulse when present.
    private func isUpwardSendCone(translation: CGSize, predictedEnd: CGSize) -> Bool {
        let impulse = CGSize(
            width: predictedEnd.width - translation.width,
            height: predictedEnd.height - translation.height
        )
        let dir: CGSize
        if hypot(impulse.width, impulse.height) >= 24 {
            dir = impulse
        } else {
            dir = translation
        }
        guard dir.height < -8 else { return false }
        let degreesFromUp = abs(atan2(dir.width, -dir.height) * 180 / .pi)
        return degreesFromUp <= 60
    }

    private func commitSendFlick(translation: CGSize, predictedEnd: CGSize) {
        isFlickBusy = true
        isSendingCaption = true

        let sent = p2pInbox.broadcast(
            speechService.currentText.trimmingCharacters(in: .whitespacesAndNewlines),
            from: appState.displayName
        )
        guard sent else {
            // Rare (radio tore down mid-flick): spring home, don’t pretend it’s a bad angle.
            isSendingCaption = false
            isFlickBusy = false
            resetCaptionTransform(animated: true)
            return
        }

        if micController.isRecording {
            micController.stopRecording()
        }
        saveCurrentTextToHistory()

        let impulse = CGSize(
            width: predictedEnd.width - translation.width,
            height: predictedEnd.height - translation.height
        )
        let speed = max(hypot(impulse.width, impulse.height), hypot(translation.width, translation.height))
        let travel = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width) * 1.15
        let length = max(hypot(translation.width, translation.height), 1)
        let end = CGSize(
            width: translation.width / length * travel,
            height: translation.height / length * travel
        )
        // Faster flick → shorter flight (clamped for readability).
        let duration = min(0.55, max(0.28, 420 / max(speed, 280)))

        withAnimation(.easeOut(duration: duration)) {
            captionOffset = end
            captionOpacity = 0
            captionScale = 0.92
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            speechService.currentText = ""
            resetCaptionTransform(animated: false)
            isSendingCaption = false
            showCanvasFeedback(.sent) {
                isFlickBusy = false
            }
        }
    }

    private func showTryAgainAndRestore() {
        isFlickBusy = true

        withAnimation(.easeOut(duration: 0.18)) {
            captionOpacity = 0
            captionScale = 0.96
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            captionOffset = .zero
            captionScale = 1
            // Opacity stays 0 so the caption doesn’t flash under “Try again”.
            showCanvasFeedback(.tryAgain) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    captionOpacity = 1
                    captionScale = 1
                }
                isFlickBusy = false
            }
        }
    }

    private func showCanvasFeedback(_ feedback: CanvasFeedback, then completion: @escaping () -> Void) {
        canvasFeedback = feedback
        canvasFeedbackOpacity = 1
        withAnimation(.easeOut(duration: 0.8)) {
            canvasFeedbackOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            canvasFeedback = nil
            canvasFeedbackOpacity = 1
            completion()
        }
    }

    private func resetCaptionTransform(animated: Bool) {
        let apply = {
            captionOffset = .zero
            captionOpacity = 1
            captionScale = 1
        }
        if animated {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78), apply)
        } else {
            apply()
        }
    }

    /// Saves the current text to history if it's valid and different from the last saved caption
    private func saveCurrentTextToHistory(source: CaptionSource? = nil) {
        let text = speechService.currentText
        guard !text.isEmpty else { return }
        
        // Check if it's different from the last saved caption
        let lastCaption = historyManager.sortedCaptions.first
        guard lastCaption?.text != text else { return }
        
        let resolved = source ?? lastCaptionSource
        let caption = CaptionText(
            text: text,
            timestamp: Date(),
            hasEmojis: true,
            source: resolved
        )
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
            lastCaptionSource = .shake
            
            // Save pickup line to history
            let caption = CaptionText(
                text: pickupLine,
                timestamp: Date(),
                hasEmojis: false,
                source: .shake
            )
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
