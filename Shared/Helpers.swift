//
//  Helpers.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 5/23/26.
//

import Foundation

/// Encapsulates photo errors (makes it easier to construct `Result` types)
enum PhotoImportError: LocalizedError {
    case noContentType
    case noData

    var errorDescription: String? {
        switch self {
        case .noContentType: return "Selected item has no known content type."
        case .noData: return "Selected item produced no data."
        }
    }
}

/// Encryption modes
enum EncryptionMode {
    case encrypt
    case decrypt
}
