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

Token Management: Hardcoded user FCM token for notification targeting to one user

### Backend (AWS Lambda + Firebase)

Runtime: Node.js with firebase-admin package

Trigger: HTTP requests from iOS app containing notification token

## Development Environment

Platform: AWS EC2 Mac instance

IDE: XCode

Language: Swift with SwiftUI framework

Deployment: XCode Cloud, TestFlight

## Security Notes

This implementation uses a hardcoded FCM token for simplicity and is intended for limited TestFlight distribution only.

#

<img src="https://github.com/user-attachments/assets/eced087d-5dff-49ce-8373-d2c127c2ce8d" width="256">
