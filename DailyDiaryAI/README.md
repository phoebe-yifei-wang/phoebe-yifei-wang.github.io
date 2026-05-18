# DailyDiaryAI (iOS SwiftUI app)

A clean, minimal daily diary app concept with a dark-blue visual theme.

## Features
- Minimal SwiftUI interface
- Written diary input
- Verbal diary input using Speech framework
- AI rewrite function to improve language style

## Setup
1. Open `DailyDiaryAIApp.swift` project files in Xcode (or copy into a new SwiftUI App project).
2. Add `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription` to Info.plist.
3. Set your API key in `AIRewriteService` (prefer secure storage / backend proxy in production).

## Notes
This repo contains source files and architecture for the app; you may package these into a standard Xcode project target.
