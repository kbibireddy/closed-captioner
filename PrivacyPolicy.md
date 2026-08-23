# Privacy Policy for Closed Captioner

**Effective Date:** October 31, 2025

**Last Updated:** August 23, 2026

## 1. Introduction

RaveSociety ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application **Closed Captioner** (the "App"). Please read this privacy policy carefully to understand our practices regarding your personal data and how we treat it.

By downloading, installing, accessing, or using our App, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy. If you do not agree with this policy, please do not use our App.

## 2. Information We Collect

Closed Captioner processes information for app features and, when ads are shown, for advertising through Google AdMob. Some data stays only on your device; other data is handled by Apple or Google as described below.

### 2.1 Audio Data (Microphone Input)
- **What we collect:** Audio from your device's microphone when you use speech-to-text
- **How we collect it:** Through the microphone with your explicit iOS permission
- **Why we collect it:** App Functionality — real-time speech-to-text transcription
- **How we use it:** Audio is sent to **Apple's Speech Recognition** service for transcription (subject to Apple's privacy policy). We do **not** store microphone recordings in the App, and we do **not** use audio for advertising or tracking
- **App Privacy label:** Audio Data — not used for tracking; not linked to your identity by us

### 2.2 Transcribed Text and Caption History (On-Device Only)
- **What we process:** Text transcriptions, edits, and caption history with timestamps
- **How we process it:** Created when you use speech-to-text or edit text; history may save captions with 2+ words
- **Why:** App Functionality — display captions, history, and export (text, PDF, HTML)
- **Storage:** Stored **only on your device** (UserDefaults). We do **not** transmit captions or history to our servers or to AdMob
- **App Privacy label:** Generally not declared as “collected” off-device, because it remains on-device

### 2.3 Device Motion Data (On-Device Only)
- **What we process:** Accelerometer data for the shake gesture feature
- **How:** CoreMotion, processed in real time on device
- **Why:** App Functionality — shake intensity for entertainment content
- **Storage:** Raw motion data is **not** stored or transmitted

### 2.4 Device ID and Advertising Data (Google AdMob)
Unless you purchase **Remove Ads**, the App shows ads via **Google AdMob** (Google Mobile Ads SDK). AdMob and its partners may collect or use:
- **Device ID** (including Identifier for Advertisers / IDFA when you allow tracking)
- **Advertising Data** (ad interactions, ad performance, and related advertising information)
- Related device and network information Google uses to serve and measure ads (for example IP address and device type, under Google's policies)

**App Privacy labels (App Store Connect):**
| Data type | Used for tracking? | Typical purposes |
|-----------|--------------------|------------------|
| Device ID | **Yes** | Third-Party Advertising; Developer's Advertising or Marketing; Analytics (ad measurement) |
| Advertising Data | **Yes** (when used for personalized ads) | Third-Party Advertising |
| Product Interaction (if applicable via AdMob) | Usually **No**, unless used for ads/tracking | Analytics and/or Advertising |

Data may be collected by **us and/or our third-party partner Google (AdMob)**. Declining tracking still allows **non-personalized** ads.

### 2.5 Purchase Information
Optional **Remove Ads** is processed by **Apple StoreKit**. We do not receive your payment card details. Purchase status may be checked on-device to disable ads. Payment data is governed by Apple's privacy policy.

### 2.6 Usage Preferences (On-Device Only)
App settings and preferences stay on your device. We do **not** operate a separate analytics SDK beyond what AdMob provides for ad delivery and measurement.

### 2.7 Nearby Messages (Optional, On-Device / Local Network)
If you turn **on** the radio control, the App may receive short text messages from other Closed Captioner peers (or a local test tool) over **Bluetooth or the local network** using Apple Multipeer Connectivity. This is **off by default**.
- Messages stay on the receiving device for display. We do **not** send them to our servers or to AdMob.
- This does **not** use cellular data as a transport. If nobody nearby is emitting, nothing is received.
- Optional **Relay messages** (Settings → General → Nearby, **off by default**) may forward a message you receive to other nearby peers. Delivery is not guaranteed. Relay does nothing unless radio is also on.
- While radio is on, the App may keep advertising and browsing nearby peers if you switch apps or lock the phone, until you turn radio off, close the App, or the auto-off timer you chose in Settings (default 4 hours). iOS may still pause this to save battery.
- You can turn the radio off at any time. iOS Local Network (and Bluetooth) permission may be requested the first time you enable it.

## 3. How We Collect Information

- **Directly from you:** Speech-to-text, text editing, history, purchases
- **Automatically via permissions:** Microphone, Speech Recognition, and (for personalized ads) App Tracking Transparency
- **Through third parties:** Apple (Speech Recognition, StoreKit) and Google AdMob (advertising)
- **On device:** Motion sensors for shake detection; local caption/history storage
- **Nearby (optional):** Local network or Bluetooth when you enable the radio, to receive caption messages from nearby Closed Captioner peers. Optional relay (off by default) may forward a message to other nearby peers; it never leaves the local radios. Radio may stay active in the background until you turn it off, close the App, or the auto-off timer ends.

You can revoke microphone, speech, and tracking permissions in iOS Settings at any time.

## 4. How We Use Your Information

- **App Functionality:** Speech-to-text, captions, history, export, shake features, and optional nearby message receive when the radio is on
- **Advertising:** Deliver, personalize (if allowed), and measure ads via Google AdMob unless Remove Ads is purchased
- **Tracking (as defined by Apple):** Device advertising identifiers and related advertising data may be used to track you across apps and websites owned by other companies **only if** you allow tracking via App Tracking Transparency

**We do NOT:**
- Sell your personal information
- Use your microphone audio, transcribed captions, or caption history for ad targeting
- Build marketing profiles from your caption content

## 5. Data Storage and Security

### 5.1 What Stays on Your Device
- Caption text, history, and app preferences: stored locally (UserDefaults), encrypted by iOS device encryption
- We do **not** operate our own cloud backend for captions or history

### 5.2 What Leaves the Device
- **Apple Speech Recognition:** Audio for transcription (Apple's privacy policy applies)
- **Google AdMob:** Device ID, advertising-related data, and other information Google requires to serve and measure ads (Google's privacy policy applies)
- **Apple StoreKit:** Purchase processing (Apple's privacy policy applies)
- **Nearby messages (optional):** If you enable the radio, short text may travel over Bluetooth or the local network to or from nearby Closed Captioner peers. This does not go to our servers.

### 5.3 Security
We follow iOS security practices for local storage. No method of storage or transmission is 100% secure.

## 6. Third-Party Services

### 6.1 Apple Speech Recognition Framework
- Converts speech to text
- Audio may be sent to Apple's servers
- Revoke permission in **Settings → Privacy & Security → Speech Recognition**
- Subject to [Apple's Privacy Policy](https://www.apple.com/legal/privacy/)

### 6.2 Google AdMob (Advertising)
- Loads banner and interstitial ads
- May use Device ID (including IDFA if you grant tracking), Advertising Data, and related device information
- You may see an App Tracking Transparency prompt; change anytime in **Settings → Privacy & Security → Tracking**
- Policies: [Google Privacy Policy](https://policies.google.com/privacy) and [How Google uses information from sites or apps](https://policies.google.com/technologies/partner-sites)

We do not share caption text, microphone audio, or caption history with AdMob for targeting.

### 6.3 In-App Purchases (Apple StoreKit)
- **Remove Ads** is a one-time purchase handled by Apple
- Restore via in-app **Restore Purchases** or Apple ID purchase history
- Subject to Apple's privacy policy

### 6.4 No Other Analytics Platforms
Aside from Apple Speech Recognition, Google AdMob, and Apple StoreKit, the App does not integrate additional third-party analytics or data brokers.

## 7. Data Sharing and Disclosure

**We do NOT sell, rent, or trade your personal information.**

Limited disclosure may occur as follows:
- **Advertising partners:** Google AdMob and partners may receive advertising-related device information (Section 6.2)
- **Service providers:** Apple for speech recognition and purchases
- **Legal requirements:** If required by law, court order, or authority
- **Protection of rights:** To protect our rights, property, or safety, or that of users
- **With your consent:** If you explicitly consent

## 8. Data Retention

- **Audio:** Not retained by the App after transcription; Apple may process audio under its policies
- **Text and history:** On your device until you delete items, clear history, or uninstall
- **Motion data:** Not retained
- **Ad-related data:** Retained by Google under Google's policies
- **Purchases:** Managed by Apple

## 9. Your Rights and Choices

### 9.1 Access and Deletion
- View and delete caption history in the App
- Uninstalling the App removes local caption data

### 9.2 Permission Control
- **Settings → Privacy & Security → Microphone**
- **Settings → Privacy & Security → Speech Recognition**
- **Settings → Privacy & Security → Tracking** (personalized ads / IDFA)

Revoking permissions disables related features. Caption history already saved remains until you delete it.

### 9.3 Advertising Choices
- Decline or revoke tracking for non-personalized ads
- Purchase **Remove Ads** to disable AdMob banners and interstitials

### 9.4 Data Portability
Export caption history as text, PDF, or HTML from the App.

### 9.5 Regional Rights (GDPR / CCPA and similar)
Depending on where you live, you may have rights to access, delete, correct, restrict, or object to certain processing, and to withdraw consent. Contact us (Section 17) to exercise these rights where applicable. We do not sell personal information.

## 10. Children's Privacy

**Our App is NOT intended for children under 13** (or the applicable age of consent in your jurisdiction). We do not knowingly collect personal information from children under 13.

If you believe a child has provided personal information, contact us. For users 13–18, we recommend parental supervision when using speech-to-text and advertising features.

## 11. International Users

This Privacy Policy is designed to align with GDPR (EEA), CCPA (California), COPPA, and Apple App Store privacy requirements.

Caption and history data remain on your device. Audio processed by Apple and advertising data processed by Google may be handled on servers in the United States or other countries according to those companies' policies.

## 12. California Privacy Rights

Under the CCPA/CPRA, California residents may have rights to know, delete, and opt out of sale/sharing of personal information, and to non-discrimination for exercising those rights.

**We do not sell your personal information.** Advertising-related data may be collected by Google AdMob as described in this policy. Contact us to make a privacy request.

## 13. European Economic Area (EEA) Privacy Rights

Under GDPR you may have rights to access, rectify, erase, restrict, port, object, and withdraw consent. Contact us using Section 17. AdMob and Apple act as independent controllers or processors for their respective services under their policies.

## 14. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will note material changes by updating the **Last Updated** date and posting the updated policy (including via the App Store privacy policy URL). Continued use after changes constitutes acceptance of the updated policy.

## 15. App Permissions Explained

### 15.1 Microphone
- **Purpose:** Capture audio for speech-to-text
- **Required:** Yes, for transcription

### 15.2 Speech Recognition
- **Purpose:** Apple's transcription service
- **Required:** Yes, for transcription
- **Data:** Audio may be sent to Apple

### 15.3 App Tracking Transparency
- **Purpose:** Request permission to use the advertising identifier (IDFA) for personalized ads via AdMob
- **Required:** Optional — declining still allows non-personalized ads
- **When:** Typically around first ad initialization
- **Change later:** Settings → Privacy & Security → Tracking

### 15.4 Motion & Fitness (Accelerometer)
- **Purpose:** Shake gesture entertainment feature
- **Required:** Optional
- **Data:** Processed on device only, not stored

## 16. Security Measures

- Local caption/history storage with iOS encryption
- Minimal collection for core features; advertising handled by AdMob under your tracking choice
- User control via permissions, history deletion, and Remove Ads

No method of electronic storage or transmission is 100% secure.

## 17. Contact Information

**RaveSociety**  
Email: karthikbibireddy@hotmail.com  
Website: https://github.com/kbibireddy/closed-captioner

For privacy inquiries, use the subject line **Privacy Inquiry - Closed Captioner**. We typically respond within 30 days.

## 18. Consent

By using Closed Captioner, you consent to:
- Processing described in this Privacy Policy
- Local storage of caption history on your device
- Audio processing for speech-to-text (with your permission)
- Motion processing for shake features
- Advertising via Google AdMob (unless Remove Ads is purchased), including personalized ads **only if** you allow tracking

You can withdraw consent by revoking permissions, deleting local data, purchasing Remove Ads, or uninstalling the App.

## 19. Governing Law

This Privacy Policy is governed by the laws of the United States of America, without regard to conflict-of-law principles.

## 20. App Store Privacy Summary (App Privacy Labels)

This section mirrors how we intend the App Store **App Privacy** questionnaire to read:

| Data type | Collected? | Linked to you by us? | Used for tracking? | Purposes |
|-----------|------------|----------------------|--------------------|----------|
| **Audio Data** | Yes (via Apple Speech) | No | No | App Functionality |
| **Device ID** | Yes (via AdMob) | No | **Yes** | Third-Party Advertising; Developer's Advertising or Marketing; Analytics |
| **Advertising Data** | Yes (via AdMob) | No | **Yes** | Third-Party Advertising |
| **Product Interaction** | May apply via AdMob | No | Usually No | Analytics / Advertising as applicable |
| **Captions / history** | On-device only | N/A | No | Not off-device collection |
| **Purchase History** | Handled by Apple; we do not collect card data | N/A | No | Typically not declared as our collection |

**Do you or third-party partners collect data from this app?** Yes (Apple Speech Recognition; Google AdMob).  
**Is data used for tracking?** Yes — Device ID and Advertising Data when personalized advertising is enabled under ATT.

### 20.1 Offline Functionality
Caption history and local features work offline. Network is required for App Store download, Apple speech recognition (when used), and AdMob ads.

### 20.2 No Account Required
The App does not require account creation.

### 20.3 Data Minimization
We only process what is needed for captions and, when ads are shown, what AdMob requires to serve and measure ads.

## 21. Acknowledgment

By downloading, installing, or using Closed Captioner, you acknowledge that you have read and understood this Privacy Policy. If you do not agree, do not use the App.

---

**Last Updated:** August 23, 2026

**Version:** 1.2

**Effective Date:** October 31, 2025

---

*This Privacy Policy is subject to change. Please review periodically for updates.*
