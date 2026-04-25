# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

iCryptr is a cross-platform iOS/macOS file encryption app built with SwiftUI and Apple's CommonCrypto library. It encrypts files into a custom `.icryptr` format using AES-256-CBC with PBKDF2 key derivation.

## Build & Test Commands

```bash
# Build for iOS
xcodebuild build -project iCryptr.xcodeproj -scheme "iCryptr (iOS)" -sdk iphonesimulator

# Build for macOS
xcodebuild build -project iCryptr.xcodeproj -scheme "iCryptr (macOS)" -sdk macosx

# Test iOS (run on simulator)
xcodebuild test -project iCryptr.xcodeproj -scheme "iCryptr (iOS)" -destination 'platform=iOS Simulator,name=iPhone 16'

# Test macOS
xcodebuild test -project iCryptr.xcodeproj -scheme "iCryptr (macOS)" -sdk macosx
```

No linting tools (SwiftLint/SwiftFormat) are configured.

## Architecture

All shared app logic lives in `Shared/`. Platform-specific targets (`iOS/`, `macOS/`) only contain `Info.plist` and entitlements.

### Core Encryption Pipeline

**`Shared/Models/StreamCryptor.swift`** is the primary encryption/decryption engine. It streams files in 128MB chunks using CommonCrypto's `CCCryptor` API (AES-256-CBC + PKCS7 padding). It handles both encrypting and decrypting by checking the file extension.

**`Shared/Services/EncryptionService.swift`** provides the low-level crypto primitives used by `StreamCryptor`:
- `generateKeyFromPassword()` — PBKDF2-HMAC-SHA256, 750,000 rounds, 32-byte key
- `generateSaltForKeyGeneration()` — 64-byte random salt via `SecRandomCopyBytes`
- `generateIVForFileEncryption()` — 16-byte random IV

> Note: `EncryptionService` also contains legacy file-level encrypt/decrypt functions that predate `StreamCryptor`. These are deprecated and should not be used for new work.

### Custom `.icryptr` File Format

```
[64 bytes]  Salt
[16 bytes]  Initialization Vector (IV)
[2 bytes]   Original filename length (UInt16, big-endian)
[n bytes]   Original filename (UTF-8, unencrypted)
[...]       AES-256-CBC encrypted file data
```

The original filename is stored in plaintext in the header so `StreamCryptor` can restore the correct name and extension on decryption.

### View Layer

- **`ContentView.swift`** — Home screen; entry point for file/photo selection
- **`EncryptActionView.swift`** — Handles both encrypt and decrypt flows; manages password validation, progress state, and output sharing
- **`ErrorTextField.swift`** — Reusable validated text input component
- **`ThumbnailView.swift`** — Thumbnail preview using `QLThumbnailGenerator`
- **`HelpView.swift`** — Info/help screen

Password validation (8+ chars, uppercase, lowercase, number, symbol) is enforced on the encryption path only; decryption accepts any input and fails gracefully if wrong.

### Utilities

**`Shared/Services/HelperService.swift`** handles temp file cleanup (`clearTemporaryDirectory()`), unique output path generation, and thumbnail creation. Temp files are cleaned on app backgrounding (see `iCryptrApp.swift` `scenePhase` handler).

**`ThumbnailProvider/`** is a QuickLook extension that renders `.icryptr` file thumbnails in Files.app.
