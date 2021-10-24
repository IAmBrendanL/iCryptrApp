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

struct HelperService {
    
    enum EncryptionMode {
        case encrypt
        case decrypt
    }
    
    /// Get a thumnail for a file
    /// - Parameters:
    ///   - fileURL: The URL of the file for which you want to create a thumbnail.
    ///   - size: The desired size of the thumbnails.
    ///   - scale: The scale of the thumbnails. This parameter usually represents the scale of the current screen. However, you can pass a screen scale to the initializer that isn’t the current device’s screen scale. For example, you can create thumbnails for different scales and upload them to a server in order to download them later on devices with a different screen scale.
    func thumbnail(for fileURL: URL, size: CGSize, scale: CGFloat) {
        let request = QLThumbnailGenerator
            .Request(fileAt: fileURL, size: size, scale: scale,
                     representationTypes: .lowQualityThumbnail)
        QLThumbnailGenerator.shared.generateRepresentations(for: request)
        { (thumbnail, type, error) in
            DispatchQueue.main.async {
                if thumbnail == nil || error != nil {
                    // Handle the error case gracefully.
                } else {
                    // Display the thumbnail that you created.
                }
            }
        }
    }
}
