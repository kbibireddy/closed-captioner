# Privacy Policy for Closed Captioner

**Effective Date:** October 31, 2025

**Last Updated:** July 27, 2026

## 1. Introduction

RaveSociety ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application **Closed Captioner** (the "App"). Please read this privacy policy carefully to understand our practices regarding your personal data and how we treat it.

By downloading, installing, accessing, or using our App, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy. If you do not agree with this policy, please do not use our App.

## 2. Information We Collect

Closed Captioner is designed with privacy in mind. We collect and process the following types of information:

### 2.1 Audio Data (Microphone Input)
- **What we collect:** Audio recordings from your device's microphone when you use the speech-to-text feature
- **How we collect it:** Through your device's microphone with your explicit permission via iOS permission prompts
- **Why we collect it:** To provide real-time speech-to-text transcription functionality
- **How we use it:** Audio is processed locally on your device using Apple's Speech Recognition framework to convert speech to text. Audio data is **NOT** stored, saved, or transmitted anywhere - it is processed in real-time and immediately discarded after transcription

### 2.2 Transcribed Text Data
- **What we collect:** Text transcriptions of your speech, including any edits you make
- **How we collect it:** When you use the speech-to-text feature or manually enter/edit text
- **Why we collect it:** To display captions and provide app functionality
- **How we use it:** Text is stored locally on your device in UserDefaults for:
  - Display as on-screen captions
  - Caption history (optional feature)
  - Export functionality (text, PDF, HTML formats)

### 2.3 Caption History
- **What we collect:** Previous caption entries with timestamps
- **How we collect it:** Automatically when you create captions (if caption contains 2+ words)
- **Why we collect it:** To provide history browsing and recall functionality
- **How we use it:** History is stored locally on your device using iOS UserDefaults. You can delete individual items or clear all history at any time through the app interface

### 2.4 Device Motion Data
- **What we collect:** Accelerometer data when using the shake gesture feature
- **How we collect it:** Through your device's motion sensors (CoreMotion framework)
- **Why we collect it:** To detect shake gestures for the pickup lines feature
- **How we use it:** Motion data is processed locally in real-time to calculate shake intensity. Raw motion data is **NOT** stored or transmitted - only the calculated shake strength is used momentarily to select appropriate content

### 2.5 Usage Information
- **What we collect:** Information about how you interact with the App (features used, settings preferences)
- **How we collect it:** Automatically through app functionality
- **Why we collect it:** To improve app performance and user experience
- **How we use it:** All usage data remains on your device. We do **NOT** collect, transmit, or analyze usage analytics

## 3. How We Collect Information

We collect information in the following ways:

- **Directly from You:** When you use app features (speech-to-text, text editing, history features)
- **Automatically:** Through iOS system permissions (microphone, speech recognition) with your explicit consent
- **Device Functionality:** Through device sensors (accelerometer) for shake detection

All data collection requires your explicit permission through iOS permission prompts. You can revoke permissions at any time through your device Settings.

## 4. How We Use Your Information

We use the information we collect for the following purposes:

- **To Provide App Functionality:** Real-time speech-to-text transcription, caption display, text editing
- **To Store History Locally:** Saving caption history on your device for your personal use
- **To Enable Features:** Shake detection for entertainment features, export functionality
- **To Improve User Experience:** Caption and history features process data locally on your device
- **To Show Advertisements:** The App displays ads via Google AdMob (see Section 6.2) unless you purchase **Remove Ads** (see Section 6.3). Ad-related identifiers and device information may be used by Google and its partners to deliver and measure ads, subject to your App Tracking Transparency choice on iOS

**IMPORTANT:** We do **NOT**:
- Sell your personal information to third parties
- Use your microphone audio, transcribed captions, or caption history for advertising targeting
- Build marketing profiles from your caption content

Caption text, audio, and history remain for app functionality only. Advertising is handled separately through Google AdMob as described below.
## 5. Data Storage and Security

### 5.1 Local Storage Only
All your data is stored **exclusively on your device** using iOS UserDefaults:
- Caption text and history: Stored locally in JSON format
- App settings and preferences: Stored locally on your device
- **NO cloud storage or remote servers are used**

### 5.2 Data Security
- All data is stored using iOS's built-in UserDefaults system
- Data is encrypted by iOS system encryption
- We follow iOS security best practices for local data storage
- No data is transmitted over networks

### 5.3 Data Transmission
**Caption and history data:** We do not transmit your transcribed captions or caption history to our own servers. Audio used for speech-to-text is processed via Apple's Speech Recognition framework (see Section 6.1).

**Advertising:** When ads are shown, the Google Mobile Ads SDK may communicate with Google's ad services and transmit device and advertising-related information as described in Section 6.2 and Google's policies. This does not include your caption text or microphone audio recordings stored by the App.
## 6. Third-Party Services

### 6.1 Apple Speech Recognition Framework
Our App uses Apple's SFSpeechRecognizer framework for speech-to-text conversion:
- **What it does:** Converts your speech to text
- **Data shared:** Audio data is sent to Apple's servers for processing (Apple's privacy policy applies)
- **Your control:** You can revoke speech recognition permission in iOS Settings at any time
- **Privacy:** Processing is subject to Apple's privacy policies and practices

**Note:** We do not control how Apple processes speech recognition data. For information about Apple's data practices, please review Apple's Privacy Policy.

### 6.2 Google AdMob (Advertising)
Our App uses **Google AdMob** (Google Mobile Ads SDK) to display banner and interstitial advertisements:

- **What it does:** Loads and displays ads within the App
- **Data that may be used:** Device identifiers (such as the Identifier for Advertisers / IDFA, if you grant tracking permission), IP address, device type, and other information Google uses to serve and measure ads
- **Your control:** On iOS you may be prompted via App Tracking Transparency (ATT). You can change tracking permission anytime in **Settings → Privacy & Security → Tracking**. Declining tracking still allows non-personalized ads
- **Privacy:** AdMob data practices are governed by [Google's Privacy Policy](https://policies.google.com/privacy) and [Google's Advertising / How Google uses information from sites or apps](https://policies.google.com/technologies/partner-sites)

We do not sell your personal information. We do not share your caption text, microphone audio, or caption history with AdMob for ad targeting.

### 6.3 In-App Purchases (Apple StoreKit)
The App offers an optional **Remove Ads** one-time purchase processed by Apple:

- **What it does:** Permanently disables banner and interstitial advertisements in the App
- **Data involved:** Purchase is handled entirely by Apple. We do not receive your payment card details
- **Your control:** Manage or restore purchases through the in-app **Restore Purchases** button or iOS **Settings → Apple ID → Subscriptions / Purchase History**
- **Privacy:** Apple's privacy policy applies to payment processing

### 6.4 No Other Analytics Platforms
Aside from Apple Speech Recognition (Section 6.1), Google AdMob (Section 6.2), and Apple StoreKit (Section 6.3), the App does not integrate additional third-party analytics or data brokers.

## 7. Data Sharing and Disclosure

**We do NOT sell, rent, or trade your personal information.**

Limited disclosure may occur as follows:

- **Advertising partners:** Google AdMob and its advertising partners may receive advertising-related device information as described in Section 6.2
- **Legal Requirements:** If required by law, court order, or governmental authority
- **Protection of Rights:** To protect our rights, property, or safety, or that of users
- **With Your Consent:** If you explicitly consent to sharing data

Even in these circumstances, we will only disclose the minimum information necessary.

## 8. Data Retention

- **Audio Data:** Audio recordings are **NOT retained**. They are processed in real-time and immediately discarded after transcription.

- **Text and History Data:** Stored locally on your device until you:
  - Delete individual items through the app
  - Clear all history through the app settings
  - Uninstall the App (which removes all local data)

- **Device Motion Data:** Motion sensor data is **NOT retained**. It is processed in real-time and discarded immediately after shake detection.

You have full control over your data retention through the app's delete and clear functions.

## 9. Your Rights and Choices

Depending on your location, you may have the following rights regarding your personal data:

### 9.1 Access Rights
You can access your caption history at any time through the app's history feature.

### 9.2 Deletion Rights
You can delete your data at any time by:
- Deleting individual caption entries through the app
- Clearing all caption history through the app
- Revoking microphone and speech recognition permissions in iOS Settings
- Uninstalling the App (removes all local data)

### 9.3 Permission Control
You can control permissions at any time through iOS Settings:
- Settings > Privacy & Security > Microphone
- Settings > Privacy & Security > Speech Recognition

Revoking permissions will disable related features but will not affect previously stored caption history (which you can delete separately).

### 9.4 Data Portability
You can export your caption history in multiple formats (text, PDF, HTML) using the app's export functionality.

### 9.5 Objection Rights
You have the right to object to processing of your personal data. Since we process data only locally for app functionality, you can stop processing by:
- Not using speech-to-text features
- Clearing history and not creating new captions
- Revoking permissions

## 10. Children's Privacy

**Our App is NOT intended for children under the age of 13** (or the applicable age of consent in your jurisdiction). We do not knowingly collect personal information from children under 13.

If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately. If we become aware that we have collected personal information from children under 13 without verification of parental consent, we will take steps to delete that information from our records.

For users between 13 and 18, we recommend parental supervision when using speech-to-text features.

## 11. International Users

This Privacy Policy is designed to comply with:
- **General Data Protection Regulation (GDPR)** - For users in the European Economic Area (EEA)
- **California Consumer Privacy Act (CCPA)** - For users in California, USA
- **Children's Online Privacy Protection Act (COPPA)** - For users under 13
- **App Store Guidelines** - Apple's privacy requirements

If you are located outside the United States, please note that:
- All data processing occurs on your device
- No data is transferred across borders
- Your data remains subject to the laws of your jurisdiction

## 12. California Privacy Rights

If you are a California resident, under the California Consumer Privacy Act (CCPA), you have the right to:
- Know what personal information we collect and how it's used
- Delete your personal information
- Opt-out of the sale of personal information (we do not sell data)
- Non-discrimination for exercising your privacy rights

**We do NOT sell your personal information.** All data remains on your device.

## 13. European Economic Area (EEA) Privacy Rights

If you are located in the EEA, under GDPR, you have the right to:
- Access your personal data
- Rectify inaccurate data
- Erase your personal data
- Restrict processing
- Data portability
- Object to processing
- Withdraw consent

To exercise these rights, please contact us using the information in Section 17.

## 14. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or other factors. We will notify you of any material changes by:
- Updating the "Last Updated" date at the top of this policy
- Posting the updated policy in the App Store listing
- Making the policy available within the App (if applicable)

We encourage you to review this Privacy Policy periodically to stay informed about how we protect your information.

**Continued use of the App after changes constitutes acceptance of the updated policy.**

## 15. App Permissions Explained

This App requests the following iOS permissions:

### 15.1 Microphone Permission
- **Purpose:** To capture audio for speech-to-text conversion
- **When requested:** When you first use the microphone feature
- **Required:** Yes, for speech-to-text functionality
- **Data usage:** Audio is processed locally and not stored

### 15.2 Speech Recognition Permission
- **Purpose:** To use Apple's Speech Recognition framework for transcription
- **When requested:** When you first use the speech-to-text feature
- **Required:** Yes, for transcription functionality
- **Data usage:** Audio may be sent to Apple's servers for processing (subject to Apple's privacy policy)

### 15.3 Motion & Fitness (Accelerometer)
- **Purpose:** To detect shake gestures for entertainment features
- **When requested:** Automatically (no iOS permission prompt required)
- **Required:** Optional, for shake detection feature only
- **Data usage:** Motion data processed locally, not stored

## 16. Security Measures

We implement appropriate technical and organizational measures to protect your information:

- **Local Storage Only:** All data remains on your device
- **iOS System Encryption:** Data benefits from iOS's built-in encryption
- **No Network Transmission:** No data sent over networks (except Apple's speech recognition, which you control)
- **Minimal Data Collection:** We only collect data necessary for app functionality
- **User Control:** You have full control over data deletion and permissions

However, no method of electronic storage or transmission is 100% secure. While we strive to protect your information, we cannot guarantee absolute security.

## 17. Contact Information

If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us at:

**RaveSociety**
Email: karthikbibireddy@hotmail.com
Website: https://github.com/kbibireddy/closed-captioner

**For Privacy-Specific Inquiries:**
Please use the subject line "Privacy Inquiry - Closed Captioner" when contacting us.

We will respond to your inquiry within a reasonable timeframe, typically within 30 days.

## 18. Consent

By using Closed Captioner, you consent to:
- The collection and use of information as described in this Privacy Policy
- Local storage of your caption history on your device
- Processing of audio data for speech-to-text functionality (subject to your permission)
- Processing of motion data for shake detection features

You can withdraw consent at any time by:
- Revoking permissions in iOS Settings
- Deleting your data through the app
- Uninstalling the App

## 19. Governing Law

This Privacy Policy is governed by and construed in accordance with the laws of the United States of America, without regard to its conflict of law principles.

## 20. Additional Information

### 20.1 No Account Required
Closed Captioner does not require account creation or user registration. All features work without creating an account.

### 20.2 Offline Functionality
Caption history and local features work without a network connection. Internet connectivity is required for:
- Initial app download from the App Store
- Apple's speech recognition service (if used)
- Loading and displaying advertisements via Google AdMob

### 20.3 Advertising and Tracking
The App shows ads through Google AdMob. Personalized advertising may use the device advertising identifier if you allow App Tracking Transparency. You can deny or revoke tracking in iOS Settings. We do not use separate analytics SDKs beyond what AdMob provides for ad delivery and measurement.

### 20.4 Data Minimization
We follow the principle of data minimization - we only collect and process data that is absolutely necessary for app functionality.

## 21. Acknowledgment

By downloading, installing, or using Closed Captioner, you acknowledge that you have read and understood this Privacy Policy and agree to its terms. If you do not agree with any part of this policy, please do not use our App.

---

**Last Updated:** July 27, 2026

**Version:** 1.1

**Effective Date:** October 31, 2025

---

*This Privacy Policy is subject to change. Please review periodically for updates.*

