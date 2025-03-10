//
//  ThumbnailProvider.swift
//  ThumbnailProvider
//
//  Created by Brendan Lindsey on 3/25/24.
//

import UIKit
import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        // Create a simple thumbnail with a solid green background and a lock icon
        let reply = QLThumbnailReply(contextSize: request.maximumSize) { context in
            let rect = CGRect(origin: .zero, size: request.maximumSize)
            
            // Fill the entire background with a solid green color
            UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0).setFill()
            UIBezierPath(rect: rect).fill()
            
            // Draw a simple white lock icon
            let lockSize = min(rect.width, rect.height) * 0.4
            let lockX = (rect.width - lockSize) / 2
            let lockY = (rect.height - lockSize) / 2
            
            // Draw lock body (rectangle with rounded corners)
            let lockBodyRect = CGRect(
                x: lockX,
                y: lockY + lockSize * 0.3,
                width: lockSize,
                height: lockSize * 0.7
            )
            let lockBodyPath = UIBezierPath(roundedRect: lockBodyRect, cornerRadius: lockSize * 0.1)
            UIColor.white.setFill()
            lockBodyPath.fill()
            
            // Draw lock shackle (U shape)
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
            shacklePath.lineWidth = lockSize * 0.1
            UIColor.white.setStroke()
            shacklePath.stroke()
            
            // Add "iCryptr" text at the bottom
            let text = "iCryptr"
            let fontSize = min(rect.width, rect.height) * 0.1
            let font = UIFont.boldSystemFont(ofSize: fontSize)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: (rect.width - textSize.width) / 2,
                y: rect.height - textSize.height - 20,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: textAttributes)
            
            return true
        }
        
        reply.extensionBadge = "iCryptr"
        handler(reply, nil)
    }
}
