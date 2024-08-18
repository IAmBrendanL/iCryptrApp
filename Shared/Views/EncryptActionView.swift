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
    @Binding var fileURL: URL?
    @Binding var pickedPhoto: PhotosPickerItem?
    @State private var outputLocation: URL?
    @State private var photo: UIImage?
    @State private var encryptionPassword: String = ""
    @State private var encryptionVerifyPassword: String = ""
    @State private var newFileName: String = ""
    @State private var encryptionStatus: EncryptionProgress = .notStarted
    @State private var fileNameError: String? = nil
    @State private var passwordError: String? = nil
    @State private var verifyError: String? = nil
    @FocusState private var focusedField: FocusableField?
    
    var fileName: String {
        if fileURL != nil {
            return fileURL!.deletingPathExtension().lastPathComponent
        } else if pickedPhoto != nil {
            return pickedPhoto?.itemIdentifier ?? "Photo"
        }
        return "Name not found"
    }
   
    var encryptionMode: EncryptionMode {
        if let fileExtension = fileURL?.pathExtension {
            return fileExtension == "iCryptr" ? .decrypt : .encrypt
        }
        return .encrypt
    }

    var photoThumbnail: UIImage? {
        if pickedPhoto != nil {
            var supported: [UTType] = []
            pickedPhoto?.supportedContentTypes.forEach() { type in
                supported.append(type)
            }
            // Task {
            //     let thing = try? await pickedPhoto?.loadTransferable(type: Image.self)
            // }
            // print("Identifier: ", pickedPhoto?.itemIdentifier)
        }
        return nil
    }
    
    
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
        encryptionStatus = .inProgress
        NSLog("Starting Encryption")
        Task(priority: .userInitiated) {
            if let unwrappedFileURL = fileURL {
                /* Stream Cryptor Implementation */
                 let cryptor = try? StreamCryptor(fileLoc: unwrappedFileURL, forOperation: encryptionMode, withPassword: encryptionPassword)
                 if cryptor != nil  {
                     self.outputLocation = cryptor!.cryptFile(newName: encryptionMode == .encrypt ? newFileName : nil)
                 }
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
        // The password must contain at least one uppercase letter, one lowercase letter, one number, and be at least 8 characters long
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        passwordError = passwordPredicate.evaluate(with: encryptionPassword) ? nil : "The password must contain at least one uppercase letter, one lowercase letter, one number, and be at least 8 characters long"
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
                    if let fileURL = fileURL {
                        ThumbnailView(fileURL: fileURL)
                    } else if photoThumbnail != nil {
                        // TODO: add view for photo thumbnail
                    }
                    Text("\(fileName)")
                        .font(.title)
                        .foregroundColor(Color.white)
                    if encryptionMode == .encrypt {
                        TextField("", text: $newFileName, prompt: Text("New File Name").foregroundStyle(Color.gray))
                            .focused($focusedField, equals: .filename)
                            .onSubmit { focusedField = .password }
                            .autocorrectionDisabled()
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(10.0)
                            .overlay() {
                                RoundedRectangle(cornerRadius: 10).stroke( fileNameError == nil ? .clear : .red, lineWidth: 4)
                            }
                            .onChange(of: newFileName) {
                                validateFileName()
                            }
                    }
                    SecureField("", text: $encryptionPassword, prompt: Text("\(encryptionMode == .encrypt ?  "Encryption" : "Decryption") Password").foregroundStyle(Color.gray))
                        .focused($focusedField, equals: .password)
                        .onSubmit { encryptionMode == .encrypt ? focusedField = .verify : nil}
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10.0)
                        .overlay() {
                            RoundedRectangle(cornerRadius: 10).stroke( passwordError == nil ? .clear: .red, lineWidth: 4)
                        }
                        .onChange(of: encryptionPassword) {
                            validatePasswordRequirements()
                        }
                
                    if encryptionMode == .encrypt {
                        SecureField("", text: $encryptionVerifyPassword, prompt: Text("Verify Password").foregroundStyle(Color.gray))
                            .focused($focusedField, equals: .verify)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(10.0)
                            .overlay() {
                                RoundedRectangle(cornerRadius: 10).stroke( verifyError == nil ? .clear: .red, lineWidth: 4)
                            }
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
                .onDisappear() {
                    pickedPhoto = nil
                    fileURL = nil
                }
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
        EncryptActionView(fileURL: .constant(URL(string: "/Users/brendan/Desktop/best-4k-wallpapers_11063030_312.jpg")!), pickedPhoto: .constant(nil))
    }
}
