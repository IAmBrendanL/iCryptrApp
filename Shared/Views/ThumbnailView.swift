//
//  ThumbnailView.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 3/16/24.
//

import SwiftUI
import QuickLookThumbnailing

struct ThumbnailView: View {
    let fileURL: URL
    @State private var thumbnail: UIImage?
    
    private func generateThumbnail() async -> UIImage? {
        fileURL.startAccessingSecurityScopedResource()
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        // Use the system thumbnail generator for all files
        let generator = QLThumbnailGenerator.shared
        let size = CGSize(width: 400, height: 400)
        let request = await QLThumbnailGenerator.Request(fileAt: fileURL, size: size, scale: UIScreen.main.scale, representationTypes: .all)
        guard let thumbnailRep = try? await generator.generateBestRepresentation(for: request) else {
            return nil
        }
        return thumbnailRep.uiImage
    }
    
    var body: some View {
        VStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
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

