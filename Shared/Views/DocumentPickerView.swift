//
//  FilePicker.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 2/9/20.
//  Copyright © 2020 Brendan Lindsey. All rights reserved.
//

import SwiftUI
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {
    @State var doc: UIDocument?
    @State var encryptionMode: HelperService.EncryptionMode?
    @Environment(\.presentationMode) var presentationMode
    
    init(encryptionMode: HelperService.EncryptionMode?) {
        self.doc = nil
        self.encryptionMode = encryptionMode
    }
    
    // MARK: - Representable Protocol Methods
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .open)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
    
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for rawURL in urls {
                if parent.encryptionMode == HelperService.EncryptionMode.encrypt {
                    print("Managed to encrypt File: \(encryptFile(rawURL, "Test", rawURL.lastPathComponent))")
                } else {
                    print("Managed to decrypt File: \(decryptFile(rawURL, "Test"))")
                }
                print(rawURL.lastPathComponent)
            }
        }
    }
}

struct DocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
        DocumentPicker(encryptionMode: HelperService.EncryptionMode.encrypt)
    }
}
