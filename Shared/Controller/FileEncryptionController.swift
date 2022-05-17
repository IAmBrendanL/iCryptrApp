//
//  FileEncryptionController.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 8/22/21.
//

import Foundation

class FileEncryptionController {
    // This class takes in a file and performs all actions to encrypt/decrypt the file
    fileprivate let plaintext: InputStream
    
    init(withPlaintext: InputStream) {
        plaintext = withPlaintext
    }
    

    func EncryptFile() {
        // while plaintext has bytes preform encryption
    
    }
    
    func DecryptFile() {
        
    }
}
