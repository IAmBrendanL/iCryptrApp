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
    @State private var photo: UIImage?
    @State private var encryptionPassword: String = ""
    @State private var encryptionVerifyPassword: String = ""
    @State private var newFileName: String = ""
    @State private var encryptionStatus: EncryptionProgress = .notStarted
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
        encryptionStatus = .inProgress
        print("In progress")
        Task(priority: .userInitiated) {
            if let unwrappedFileURL = fileURL {
                /* Stream Cryptor Implementation */
                 let cryptor = try? StreamCryptor(fileLoc: unwrappedFileURL, forOperation: encryptionMode, withPassword: encryptionPassword)
                 if cryptor != nil  {
                     let success = cryptor!.cryptFile(newName: encryptionMode == .encrypt ? newFileName : nil)
                     print(success ? "Succeeded encrypting" : "Failed encrypting")
                 }
                /* In-Memory Implementation */
                /*
                if encryptionMode == .encrypt  {
                    let success = encryptFile(unwrappedFileURL, encryptionPassword, newFileName)
                    print(success ? "Succeeded encrypting" : "Failed encrypting")
                } else {
                    let success = decryptFile(unwrappedFileURL, encryptionPassword)
                    print(success ? "Succeeded decrypting" : "Failed decrypting")
                }
                 */
            }
            encryptionStatus = .completed
        }
    }
    
    func validateFileName() -> Bool {
        let fileNameRegex = "^[a-zA-Z0-9_-]{1,}$"
        let fileNamePredicate = NSPredicate(format: "SELF MATCHES %@", fileNameRegex)
        return fileNamePredicate.evaluate(with: newFileName)
    }
    
    func validatePasswordRequirements() -> Bool {
        // The password must contain at least one uppercase letter, one lowercase letter, one number, and be at least 8 characters long
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: encryptionPassword)
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
                        // TODO: validate the file name below
                        TextField("", text: $newFileName, prompt: Text("New File Name").foregroundStyle(Color.gray))
                            .focused($focusedField, equals: .filename)
                            .onSubmit { focusedField = .password }
                            .autocorrectionDisabled()
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .border(Color(UIColor.separator))
                            .cornerRadius(10.0)
                    }
                    // TODO: validate a minimum length of 1
                    SecureField("", text: $encryptionPassword, prompt: Text("\(encryptionMode == .encrypt ?  "Encryption" : "Decryption") Password").foregroundStyle(Color.gray))
                        .focused($focusedField, equals: .password)
                        .onSubmit { encryptionMode == .encrypt ? focusedField = .verify : nil}
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.white)
                        .border(Color(UIColor.separator))
                        .cornerRadius(10.0)
                    if encryptionMode == .encrypt {
                        // TODO: validate that this matches the encryption password above
                        SecureField("", text: $encryptionVerifyPassword, prompt: Text("Verify Password").foregroundStyle(Color.gray))
                            .focused($focusedField, equals: .verify)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .border(Color(UIColor.separator))
                            .cornerRadius(10.0)
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
                        .background(Color.black.opacity(0.6))
                }
                if encryptionStatus == .completed {
                    ZStack {
                        Color.black
                            .opacity(0.6)
                            .ignoresSafeArea()
                        VStack {
                            Text("\(encryptionMode == .encrypt ? "Encryption" : "Decryption") Completed")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                                .padding(.top, 160)
                            Button(action: {() -> () in dismiss() }) {
                                Text("Done")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10.0)
                            }
                        }
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
