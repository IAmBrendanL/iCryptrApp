//
//  ThumbnailProvider.swift
//  ThumbnailProvider
//
//  Created by Brendan Lindsey on 3/25/24.
//

import UIKit
import QuickLookThumbnailing
import os.log

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        // Ensure the size is valid
        if request.maximumSize.width <= 0 || request.maximumSize.height <= 0 {
            let error = NSError(domain: "ThumbnailProviderErrorDomain", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Invalid size requested"])
            handler(nil, error)
            return
        }
        // Create thumbnail with exact size specification to match request dimensions
        let thumbnailSize = request.maximumSize
        let reply = QLThumbnailReply(contextSize: thumbnailSize) { () -> Bool in
            // Get the current graphics context
            guard let context = UIGraphicsGetCurrentContext() else {
                os_log("Failed to get current graphics context", type: .error)
                return false
            }
            // Save context state and defer restoring it
            context.saveGState()
            defer { context.restoreGState() }
            // Get the bounds of drawing area
            let rect = context.boundingBoxOfClipPath
            // Set scale to ensure we fill the entire canvas
            let scale = max(
                thumbnailSize.width / rect.width,
                thumbnailSize.height / rect.height
            )
            if scale > 1.0 {
                context.scaleBy(x: scale, y: scale)
            }
            // Fill background
            context.setFillColor(UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0).cgColor)
            context.fill(rect)
            // Start to draw lock
            let lockSize = min(rect.width, rect.height) * 0.5  // Changed from 0.6 to 0.5
            let lockX = (rect.width - lockSize) / 2
            let lockY = (rect.height - lockSize) / 2
            // Draw lock body
            let lockBodyRect = CGRect(
                x: lockX,
                y: lockY + lockSize * 0.3,
                width: lockSize,
                height: lockSize * 0.7
            )
            let lockBodyPath = UIBezierPath(roundedRect: lockBodyRect, cornerRadius: lockSize * 0.1)
            context.setFillColor(UIColor.white.cgColor)
            context.addPath(lockBodyPath.cgPath)
            context.fillPath()
            // Draw lock shackle
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(lockSize * 0.12)
            let shacklePath = UIBezierPath()
            shacklePath.move(to: CGPoint(x: lockX + lockSize * 0.25, y: lockY + lockSize * 0.3))
            shacklePath.addLine(to: CGPoint(x: lockX + lockSize * 0.25, y: lockY))
            shacklePath.addArc(
                withCenter: CGPoint(x: lockX + lockSize * 0.5, y: lockY),
                radius: lockSize * 0.25,
                startAngle: .pi,
                endAngle: 0,
                clockwise: true
            )
            shacklePath.addLine(to: CGPoint(x: lockX + lockSize * 0.75, y: lockY + lockSize * 0.3))
            context.addPath(shacklePath.cgPath)
            context.strokePath()
            // Add text
            let text = "iCryptr"
            let fontSize = min(rect.width, rect.height) * 0.12
            if let fontName = UIFont(name: "Helvetica-Bold", size: fontSize) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: fontName,
                    .foregroundColor: UIColor.white.cgColor,
                    .paragraphStyle: paragraphStyle
                ]
                // Calculate text size and position in bottom-center
                let attributedString = NSAttributedString(string: text, attributes: attributes)
                let textSize = attributedString.size()
                let y = rect.height - textSize.height - 40
                let x = (rect.width - textSize.width) / 2
                context.saveGState()
                // Core Text draws text upside down by default in this context
                context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
                context.translateBy(x: x, y: y + textSize.height)
                // Actually draw the text
                let line = CTLineCreateWithAttributedString(attributedString)
                CTLineDraw(line, context)
                // Restore the graphics state
                context.restoreGState()
            }
            // Ensure the context is properly flushed
            return true
        }
        
        reply.extensionBadge = "iCryptr"
        handler(reply, nil)
    }
}
