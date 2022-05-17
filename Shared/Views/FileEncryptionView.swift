//
//  FileEncryptionView.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 6/18/20.
//  Copyright © 2020 Brendan Lindsey. All rights reserved.
//

import SwiftUI


struct FileEncryptionView: View {
    @State private var password: String = ""
    @State var encryptionMode: HelperService.EncryptionMode = .encrypt
    @State private var showingAlert: Bool = false
    @State private var fileURL: URL?
    @State private var fileEncryptionResultStatus: Bool = false
    @State private var filename = ""
    
    
    init(encryptionMode: HelperService.EncryptionMode, fileURL: URL) {
        self.encryptionMode = encryptionMode
        self.fileURL = fileURL
        if let unwrappedFileURL = self.fileURL {
            filename = unwrappedFileURL.lastPathComponent
        }
    }
    
    func manipulateFile() {
        guard let unwrappedFileURL = self.fileURL else { return }
        if self.encryptionMode == HelperService.EncryptionMode.encrypt {
            fileEncryptionResultStatus = encryptFile(unwrappedFileURL, password, unwrappedFileURL.lastPathComponent)
        } else {
            fileEncryptionResultStatus = decryptFile(unwrappedFileURL, password)
        }
        showingAlert = true
    }

    var body: some View {
        VStack {
            Text(filename).font(.title)
            SecureField("Password", text: $password).background(Color.white)
                .cornerRadius(3)
                .padding(.horizontal, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            Button(action: {self.showingAlert = true}, label: {
                Text(self.encryptionMode == HelperService.EncryptionMode.encrypt ? "Encrypt" : "Decrypt")
                    .foregroundColor(Color.white)
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10.0)
                })
        }.background(Color.gray)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Important message"),
                  message: Text("\(self.encryptionMode == HelperService.EncryptionMode.encrypt ? "Encryption" : "Decryption") \(self.fileEncryptionResultStatus ? "Succeded" : "Failed")"),
                  dismissButton: .default(Text("Got it!")))
        }
    }
}

//struct FileEncryptionView_Previews: PreviewProvider {
//    static var previews: some View {
//        FileEncryptionView(encryptionMode: .decrypt, fileURL: nil)
//            .previewLayout(.sizeThatFits)
//    }
//}