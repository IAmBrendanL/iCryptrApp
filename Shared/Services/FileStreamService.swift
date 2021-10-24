//
//  FileStreamService.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 8/22/21.
//

import Foundation

class FileStreamService {
    
    func getFileStream(fromUrl: URL) -> InputStream? {
        let stream = InputStream(url: fromUrl)
        return stream
    }
    
    func getFileStream(fromData: Data ) -> InputStream? {
        let stream = InputStream(data: fromData)
        return stream
    }
}
