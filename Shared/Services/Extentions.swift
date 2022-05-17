//
//  Extentions.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 4/30/22.
//

import Foundation

extension OutputStream {
    
    func write(_ data: Data) throws {
        var remaining = data[...]
        while !remaining.isEmpty {
            let bytesWritten = remaining.withUnsafeBytes { buf in
                // The force unwrap is safe because we know that `remaining` is
                // not empty. The `assumingMemoryBound(to:)` is there just to
                // make Swift’s type checker happy. This would be unnecessary if
                // `write(_:maxLength:)` were (as it should be IMO) declared
                // using `const void *` rather than `const uint8_t *`.
                self.write(
                    buf.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    maxLength: buf.count
                )
            }
            guard bytesWritten >= 0 else {
                // … if -1, throw `streamError` …
                // … if 0, well, that’s a complex question …
                fatalError()
            }
            remaining = remaining.dropFirst(bytesWritten)
        }
    }
}

