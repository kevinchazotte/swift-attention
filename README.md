# Swift-Attention

An iOS app that sends push notifications when users tap the "boop" button.

## Overview

Swift-Attention is a SwiftUI-based iOS application with a randomly pixelated background and a central red button. When tapped, the button triggers a push notification to a paired user via Firebase Cloud Messaging.

## Features

- **Randomized UI**: Randomly generated pixelated background.
- **Push Notifications**: Sends secure alerts via Firebase Cloud Messaging.
- **Device Pairing**: Bluetooth-based exchange of notification tokens to pair devices.
- **Anonymous Authentication**: Uses Firebase Anonymous Auth for secure yet frictionless user management.

## Architecture

### iOS App (Swift/SwiftUI)

- **UI**: Randomly pixelated background with centered red "boop" button.
- **Authentication**: Firebase Anonymous Authentication.
- **Pairing**: Bluetooth Low Energy (BLE) for local token exchange, backed by Firestore for persistence.
- **Notifications**: Firebase Cloud Messaging integration.

### Backend (AWS Lambda + Firebase)

- **Runtime**: Node.js with firebase-admin package.
- **Trigger**: HTTP requests from iOS app containing notification token.
- **Database**: Firebase Firestore for user and pair management.

## Development Environment

- **Platform**: AWS EC2 Mac instance / Local macOS
- **IDE**: Xcode
- **Language**: Swift with SwiftUI framework
- **Database**: Firebase Firestore
- **Deployment**: Xcode Cloud, Firebase, App Store Connect

## Security Notes

This implementation utilizes Firebase Anonymous Authentication to secure database access. Firestore security rules ensure that users can only access their own data and can only pair with mutual consent.

## Privacy

We collect only the minimal information necessary for app functionality: your device's unique identifier (UUID) and Firebase Cloud Messaging (FCM) token. This data is stored securely in Firebase Firestore and is used solely to enable push notifications and core app features. We do not collect, store, or share any personal information beyond these technical identifiers required for the app to function.

#

<img src="https://github.com/user-attachments/assets/cae8a32a-74f7-433d-a3d8-9373922958a6" width="256">
