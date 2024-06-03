//
//  HelperService.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 6/7/20.
//  Copyright © 2020 Brendan Lindsey. All rights reserved.
//

import Foundation
import CoreGraphics
import QuickLook

enum EncryptionMode {
    case encrypt
    case decrypt
}

struct HelperService {
    
    
    /// Get a thumbnail for a file
    /// - Parameters:
    ///   - fileURL: The URL of the file for which you want to create a thumbnail.
    ///   - size: The desired size of the thumbnails.
    ///   - scale: The scale of the thumbnails. This parameter usually represents the scale of the current screen. However, you can pass a screen scale to the initializer that isn’t the current device’s screen scale. For example, you can create thumbnails for different scales and upload them to a server in order to download them later on devices with a different screen scale.
    func thumbnail(for fileURL: URL, size: CGSize, scale: CGFloat) {
        let request = QLThumbnailGenerator
            .Request(fileAt: fileURL, size: size, scale: scale,
                     representationTypes: .lowQualityThumbnail)
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { (thumbnail, type, error) in
            DispatchQueue.main.async {
                if thumbnail == nil || error != nil {
                    // Handle the error case gracefully.
                } else {
                    // Display the thumbnail that you created.
                }
            }
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
}
