# Swift-Attention

An iOS app that sends push notifications when users tap the "boop" button.

## Overview

Swift-Attention is a SwiftUI-based iOS application with a randomly pixelated background and a central red button. When tapped, the button triggers a push notification to a designated user via Firebase Cloud Messaging.

## Features

SwiftUI interface with randomly generated background

Push notification system using Firebase Cloud Messaging

AWS Lambda backend for notification routing

TestFlight distribution for select users

## Architecture

### iOS App (Swift/SwiftUI)

UI: Randomly pixelated background with centered red "boop" button

Notifications: Firebase Cloud Messaging integration

Token Management: Tokens are stored in a Firebase Firestore database and queried on sending a notification

### Backend (AWS Lambda + Firebase)

Runtime: Node.js with firebase-admin package

Trigger: HTTP requests from iOS app containing notification token

## Development Environment

Platform: AWS EC2 Mac instance

IDE: XCode

Language: Swift with SwiftUI framework

Database: Firebase Firestore

Deployment: XCode Cloud, Firebase, App Store Connect

## Security Notes

This implementation utilizes Firebase Firestore's database and has all the security guarantees associated with it. Minimal user information is stored and is only stored for required functional purposes.

## Privacy

We collect only the minimal information necessary for app functionality: your device's unique identifier (UUID) and Firebase Cloud Messaging (FCM) token. This data is stored securely in Firebase Firestore and is used solely to enable push notifications and core app features. We do not collect, store, or share any personal information beyond these technical identifiers required for the app to function.

#

<img src="https://github.com/user-attachments/assets/cae8a32a-74f7-433d-a3d8-9373922958a6" width="256">
