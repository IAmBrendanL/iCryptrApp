//
//  ThumbnailView.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 3/16/24.
//

import SwiftUI
import QuickLookThumbnailing
import os.log

#if canImport(UIKit)
import UIKit
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#endif

private extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}


struct ThumbnailView: View {
    let fileURL: URL
    @State private var thumbnail: PlatformImage?
    
    /// Generates thumbnails for images using the correct library for macOS or iOS 
    /// - Returns: an Image or nil if the thumbnail could not be generated
    private func generateThumbnail() async -> PlatformImage? {
        let isInTempDirectory = fileURL.path.hasPrefix(FileManager.default.temporaryDirectory.path)
        let access = isInTempDirectory ? false : fileURL.startAccessingSecurityScopedResource()
        // if the file is not in the temporary directory and we can't access it, return early
        if !isInTempDirectory && !access {
            os_log("Failed to access security scoped resource for thumbnail generation", type: .error)
            return nil
        }
        defer {
            if access {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let generator = QLThumbnailGenerator.shared
        let size = CGSize(width: 400, height: 400)
        #if canImport(UIKit)
        let scale = UIScreen.main.scale
        #else
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        #endif
        let request = QLThumbnailGenerator.Request(fileAt: fileURL, size: size, scale: scale, representationTypes: .all)
        guard let thumbnailRep = try? await generator.generateBestRepresentation(for: request) else {
            return nil
        }
        #if canImport(UIKit)
        return thumbnailRep.uiImage
        #else
        return thumbnailRep.nsImage
        #endif
    }

    var body: some View {
        VStack {
            if let thumbnail = thumbnail {
                Image(platformImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                    .shadow(radius: 3)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            }
        }
        .onAppear {
            Task {
                thumbnail = await generateThumbnail()
            }
        }
    }
}
