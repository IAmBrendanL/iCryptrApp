//
//  SwiftUIView.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 6/23/20.
//  Copyright © 2020 Brendan Lindsey. All rights reserved.
//

import SwiftUI
import UIKit
import PhotosUI

enum EncryptionProgress {
    case notStarted
    case inProgress
    case completed
}

fileprivate enum FocusableField {
    case filename
    case password
    case verify
}

struct EncryptActionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var fileURL: URL? // optional because it's possible for this to be nil in the home view
    @State var shouldDeleteFileOnCompletion: Bool = false
    @State private var outputLocation: URL?
    @State private var encryptionPassword: String = ""
    @State private var encryptionVerifyPassword: String = ""
    @State private var newFileName: String = ""
    @State private var encryptionStatus: EncryptionProgress = .notStarted
    @State private var fileNameError: String? = nil
    @State private var passwordError: String? = nil
    @State private var verifyError: String? = nil
    @FocusState private var focusedField: FocusableField?
    
    // MARK: - Computed Properties
    var fileName: String {
        return fileURL?.deletingPathExtension().lastPathComponent ?? "FilleNameMissing"
    }
    
    var encryptionMode: EncryptionMode {
        return fileURL?.pathExtension == "iCryptr" ? .decrypt : .encrypt
    }
    
    // MARK: - Methods
    /// Handles all the actions needed when a user starts an action
    func handleButtonPress() {
        // dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        // validate requirements
        validatePasswordRequirements()
        if encryptionMode == .encrypt {
            validateFileName()
            validateVerifyPasswordRequirements()
        }
        if fileNameError != nil || passwordError != nil || verifyError != nil {
            // TODO: Show an alert with at least one of the error messages and or make the button default to greyed out _unless_ all conditions are met
            return
        }
        if fileURL == nil {
            // TODO show an alert
            return
        }
        encryptionStatus = .inProgress
        NSLog("Starting Encryption")
        Task(priority: .userInitiated) {
            /* Stream Cryptor Implementation */
            let cryptor = try? StreamCryptor(fileLoc: fileURL!, forOperation: encryptionMode, withPassword: encryptionPassword)
            if cryptor != nil  {
                self.outputLocation = cryptor!.cryptFile(newName: encryptionMode == .encrypt ? newFileName : nil)
            }
            if self.shouldDeleteFileOnCompletion {
                HelperService.deleteFile(at: fileURL!)
            }
            encryptionStatus = .completed
        }
    }
    
    /// Validates that the file name matches the rules and sets any required error messages
    func validateFileName() {
        // allow letters, numbers, underscore, & hyphens to make up the file name
        let fileNameRegex = "^[a-zA-Z0-9_-]{1,}$"
        let fileNamePredicate = NSPredicate(format: "SELF MATCHES %@", fileNameRegex)
        fileNameError = fileNamePredicate.evaluate(with: newFileName) ? nil : "File name not valid"
        // TODO: Allow file names to have spaces but only if they're not the only, first, or last character
    }
    
    /// Validates the password requirements and sets any required error messages
    func validatePasswordRequirements() {
        // Check each requirement individually and return the first error found
        if encryptionMode == .decrypt {
            return
        }
        if encryptionPassword.count < 8 {
            passwordError = "Must be at least 8 characters long"
        } else if !encryptionPassword.contains(where: { $0.isUppercase }) {
            passwordError = "Must contain at least one uppercase letter"
        } else if !encryptionPassword.contains(where: { $0.isLowercase }) {
            passwordError = "Must contain at least one lowercase letter"
        } else if !encryptionPassword.contains(where: { $0.isNumber }) {
            passwordError = "Must contain at least one number"
        } else if !encryptionPassword.contains(where: { $0.isSymbol || $0.isPunctuation || $0 == " " }) {
            passwordError = "Must contain at least one special character"
        } else {
            passwordError = nil
        }
    }
    
    /// Validates the verification password requirements and sets any required error messages
    func validateVerifyPasswordRequirements() {
        verifyError = encryptionVerifyPassword == encryptionPassword ? nil : "Passwords must match"
        verifyError = encryptionPassword.count > 1 ? verifyError : "Cannot be blank"
    }
    
    /// Opens the file app to the encrypted or decrypted file
    func viewOutputFile() {
        if outputLocation != nil {
            let shareLocation = outputLocation!.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
            UIApplication.shared.open(URL(string: shareLocation)!)
        } else {
           // TODO: theoretically... we shouldn't get here if the display logic stays the same but we should consider handling it better
           dismiss()
        }
    }
    
    var body: some View {
        ZStack {
            Color.gray.edgesIgnoringSafeArea(.all)
            ZStack {
                VStack {
                    if fileURL != nil { // TODO: make the thumbnail for the iCryptr filetype
                        ThumbnailView(fileURL: fileURL!)
                    }
                    Text("\(fileName)")
                        .font(.title)
                        .foregroundColor(Color.white)
                    if encryptionMode == .encrypt {
                        ErrorTextField(
                            title: "New File Name",
                            text: $newFileName,
                            errorMessage: fileNameError,
                            onSubmit: { focusedField = .password }
                        )
                        .focused($focusedField, equals: .filename)
                        .onChange(of: newFileName) {
                            validateFileName()
                        }
                    }
                    ErrorTextField(
                        title: "\(encryptionMode == .encrypt ? "Encryption" : "Decryption") Password",
                        text: $encryptionPassword,
                        errorMessage: passwordError,
                        isSecure: true,
                        onSubmit: { encryptionMode == .encrypt ? focusedField = .verify : nil }
                    )
                    .focused($focusedField, equals: .password)
                    .onChange(of: encryptionPassword) {
                        validatePasswordRequirements()
                    }
                
                    if encryptionMode == .encrypt {
                        ErrorTextField(
                            title: "Verify Password",
                            text: $encryptionVerifyPassword,
                            errorMessage: verifyError,
                            isSecure: true
                        )
                        .focused($focusedField, equals: .verify)
                        .onChange(of: encryptionVerifyPassword) {
                            validateVerifyPasswordRequirements()
                        }
                    }
                    
                    Button(action: {() -> () in handleButtonPress()}, label: {
                        Text("  Start \(encryptionMode == .encrypt ?  "Encryption" : "Decryption")  ")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10.0)
                    })
                }
                .padding(20)
                if encryptionStatus == .inProgress {
                    ProgressView("\(encryptionMode == .encrypt ? "Encryption" : "Decryption") in Progress")
                        .tint(.white)
                        .font(.title2)
                        .foregroundColor(.white)
                        .controlSize(.large)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.8))
                }
                if encryptionStatus == .completed {
                    ZStack {
                        Color.black
                            .opacity(0.8)
                            .ignoresSafeArea()
                        VStack {
                            Text("\(encryptionMode == .encrypt ? "Encryption" : "Decryption") \(outputLocation != nil ? "Completed" : "Failed")")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                                .padding(.top, 160)
                            if outputLocation != nil {
                                Button(action: viewOutputFile) {
                                    Text("View File")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10.0)
                                }
                                .padding(.bottom, 10)
                            }
                            Button(action: {() -> () in dismiss() }) {
                                Text("Close")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .padding()
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(10.0)
                            }
                        }
                        .padding()
                        .cornerRadius(10.0)
                    }
                }
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        EncryptActionView(fileURL: .constant(URL(string: "/Users/brendan/Desktop/best-4k-wallpapers_11063030_312.icryptr")!))
    }
}
