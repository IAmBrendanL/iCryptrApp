//
//  HelperService.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 6/7/20.
//  Copyright © 2020 Brendan Lindsey. All rights reserved.
//

import Foundation
import CoreGraphics

enum EncryptionMode {
    case encrypt
    case decrypt
}

struct HelperService {

    static var isProcessing = false

    /// Removes all files from the app's temporary directory.
    static func clearTemporaryDirectory() {
        let fileManager = FileManager.default
        let tmpURL = fileManager.temporaryDirectory
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: tmpURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing temporary directory: \(error)")
        }
    }

    /// Returns a URL for the output file with the specified name and file extension in the documents directory. Tries
    /// appending a number to the file name if the file already exists up to 10000 times.
    /// - Parameters:
    ///   - fileName: The name of the output file.
    ///   - fileExtension: The file extension of the output file.
    /// - Returns: The URL for the output file in the documents directory, or nil if the file does not exist.
    static func getOutputPathInDocumentsDirectory(named fileName: String, withExtension fileExtension: String) -> URL? {
        let fManager = FileManager.default
        let dirURL_tmp = fManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var fileURL =  dirURL_tmp.appendingPathComponent(fileName+"."+fileExtension)
        for i in 1...10000 {
            // check if file exists and either try to write the file or update the filename)
            if !fManager.fileExists(atPath: fileURL.path) {
                return fileURL
            } else {
                fileURL = dirURL_tmp.appendingPathComponent("\(fileName)-\(String(i)).\(fileExtension)")
            }
        }
        // if here then in 10000 iterations no filename was found to be available
        return nil
    }

    /// Deletes the file at the specified URL.
    /// - Parameter fileURL: The URL of the file to delete.
    static func deleteFile(at fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}
