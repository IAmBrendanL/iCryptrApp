//
//  StreamCryptor.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 3/24/20.
//  Copyright © 2020 Brendan Lindsey. All rights reserved.
//

import Foundation
import CommonCrypto
import SwiftUI


struct CryptoError: Error {
    let status: CCCryptorStatus
    let errorMessage: String? = nil
}

/// Holds unpacked data from an encrypted file for use when decrypting the file
struct UnpackedFile {
    let iv: Data
    let salt: Data
    let fileNameAndTypeData: String
    let fileDataOffset: UInt64
    let storedHMAC: Data
}

class StreamCryptor {
    private static let magicV2: [UInt8] = [0x69, 0x43, 0x52, 0x02]
    private static let hmacSize: Int = 32   // CC_SHA256_DIGEST_LENGTH

    private let operation: CCOperation
    private let inFileLocation: URL
    private var status: CCCryptorStatus = CCCryptorStatus(kCCUnspecifiedError)
    private let cryptorRef = UnsafeMutablePointer<CCCryptorRef?>.allocate(capacity: 1)
    private var buffer = Data()
    private var outputLocation: URL?
    private var iv: Data
    private var salt: Data
    private var fileOffset: UInt64 = 0
    private var fileNameAndTypeData: String? = nil
    private var hmacKey: Data?
    private var storedHMAC: Data?
    
   
    public init(fileLoc: URL, forOperation: EncryptionMode, withPassword password: String, withNewName newName: String? = nil ) throws {
        self.inFileLocation = fileLoc
        self.operation = forOperation == .encrypt ? CCOperation(kCCEncrypt) : CCOperation(kCCDecrypt)
        if forOperation == .encrypt {
            guard let salt = generateSaltForKeyGeneration() else { throw CryptoError(status: CCStatus(kCCUnspecifiedError))}
            guard let iv = generateIVForFileEncryption() else {throw CryptoError(status: CCStatus(kCCUnspecifiedError))}
            self.salt = salt
            self.iv = iv
        } else {
            // stop the compiler from yelling at me that I'm calling a method before everything is initialized.
            self.salt = Data()
            self.iv = Data()
            guard let unpackedFile = unpackEncryptedFile(atLocation: fileLoc) else { throw CryptoError(status: CCStatus(kCCUnspecifiedError))}
            self.salt = unpackedFile.salt
            self.iv = unpackedFile.iv
            self.fileOffset = unpackedFile.fileDataOffset
            self.fileNameAndTypeData = unpackedFile.fileNameAndTypeData
            self.storedHMAC = unpackedFile.storedHMAC
        }
        guard let keyMaterial = generateKeyFromPassword(password, salt, 750000,
                                                        keySize: kCCKeySizeAES256 * 2)
        else { throw CryptoError(status: CCStatus(kCCUnspecifiedError)) }
        let aesKey = Data(keyMaterial.prefix(kCCKeySizeAES256))
        self.hmacKey = Data(keyMaterial.suffix(kCCKeySizeAES256))
        aesKey.withUnsafeBytes { keyPtr in
            iv.withUnsafeBytes { ivPtr in
                let status = CCCryptorCreate(operation, CCAlgorithm(kCCAlgorithmAES),
                                             CCOptions(kCCOptionPKCS7Padding),
                                             keyPtr.baseAddress, aesKey.count,
                                             ivPtr.baseAddress, cryptorRef)
                self.status = status
            }
        }
        
        if self.status != kCCSuccess {
            throw CryptoError(status: status)
        }
        
    }
    
    /// Gets the output file URL. It makes certain to
    /// - Parameter newFileName: the name to give an encrypted file or nil if this is a file for decryption
    /// - Returns: the url to write the output file.
    private func getOutputFileURL(newFileName: String?) -> URL? {
        var name = newFileName
        var fileExtension = "iCryptr"
        if self.operation == CCOperation(kCCDecrypt) {
            guard var nameComponents = self.fileNameAndTypeData?.split(separator: ".") else { return nil }
            if nameComponents.count > 1 {
                fileExtension = String(nameComponents.popLast() ?? "")
            }
            name = nameComponents.joined()
        }
        guard name != nil else { return nil }
        let fileManager = FileManager.default
        
        if let outputLocation = HelperService.getOutputPathInDocumentsDirectory(named: name!, withExtension: fileExtension) {
            if !fileManager.fileExists(atPath: outputLocation.path) {
                fileManager.createFile(atPath: outputLocation.path, contents: nil, attributes: nil)
            }
            return outputLocation
        }
        return nil 
    }
    
    ///  Checks if we have enough space to duplicate the file while leaving at least 500 MB free on the device
    /// - Returns: a boolean indicating if we have enough space or not.
    private func checkForAvailibleSpace() -> Bool {
        //TODO: figure out why I'm still getting the occational Exception "*** -[NSConcreteFileHandle writeData:]: No space left on device"
        do {
            let values = try self.inFileLocation.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .fileSizeKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage, let currentSize = values.fileSize {
                return capacity > currentSize + (500 * 1024 * 1024)
            }
            return false
        } catch {
            return false
        }
    }
   
    
    /// Encrypt or Decrypt the file given to the stream cryptor
    /// - Parameter newFileName: the new file name to write to if this is for encryption
    /// - Returns: a url for where the file was written to if successful else nil
    public func cryptFile(newName newFileName: String?) -> URL? {
        guard !(self.operation == CCOperation(kCCEncrypt) && newFileName == nil) else { return nil }  // verify that we have a file name for encryption
        // The below is needed in some circumstances, I'm not checking the return value because I'm using `defer` which is block scoped.
        let _  = inFileLocation.startAccessingSecurityScopedResource()
        defer {
            inFileLocation.stopAccessingSecurityScopedResource()
        }
        guard checkForAvailibleSpace() else { return nil }
        guard let outputLocation = getOutputFileURL(newFileName: newFileName) else { return nil }
        guard let hmacKey = self.hmacKey else { return nil }
        do {
            let inFileHandle = try FileHandle(forReadingFrom: inFileLocation)
            defer { inFileHandle.closeFile() }
            let outFileHandle = try FileHandle(forWritingTo: outputLocation)
            defer { outFileHandle.closeFile() }

            let bufferSize = 134217728

            if self.operation == CCOperation(kCCEncrypt) {
                // --- Encryption: write header, stream ciphertext, append HMAC tag ---
                let headerData = try packFile(into: outFileHandle,
                                              preEncryptionNameAndExtension: inFileLocation.lastPathComponent)
                var hmacCtx = CCHmacContext()
                hmacKey.withUnsafeBytes {
                    CCHmacInit(&hmacCtx, CCHmacAlgorithm(kCCHmacAlgSHA256), $0.baseAddress, hmacKey.count)
                }
                headerData.withUnsafeBytes { CCHmacUpdate(&hmacCtx, $0.baseAddress, headerData.count) }

                var shouldLoop = true
                while shouldLoop {
                    autoreleasepool {
                        let data = inFileHandle.readData(ofLength: bufferSize)
                        if data.isEmpty {
                            let lastBytes = self.final()
                            outFileHandle.write(lastBytes)
                            lastBytes.withUnsafeBytes { CCHmacUpdate(&hmacCtx, $0.baseAddress, lastBytes.count) }
                            shouldLoop = false
                        } else {
                            let cypherText = self.update(with: data)
                            outFileHandle.write(cypherText)
                            cypherText.withUnsafeBytes { CCHmacUpdate(&hmacCtx, $0.baseAddress, cypherText.count) }
                        }
                    }
                }
                var tag = Data(count: StreamCryptor.hmacSize)
                tag.withUnsafeMutableBytes { CCHmacFinal(&hmacCtx, $0.baseAddress) }
                outFileHandle.write(tag)
                return self.status == CCCryptorStatus(kCCSuccess) ? outputLocation : nil

            } else {
                // --- Decryption: pass 1 verify HMAC, pass 2 decrypt ---
                guard let storedHMAC = self.storedHMAC else { return nil }

                // Pass 1: stream bytes 0..(fileSize-32) through HMAC and compare
                let fileSize = inFileHandle.seekToEndOfFile()
                let authLen = fileSize - UInt64(StreamCryptor.hmacSize)
                try inFileHandle.seek(toOffset: 0)

                var hmacCtx = CCHmacContext()
                hmacKey.withUnsafeBytes {
                    CCHmacInit(&hmacCtx, CCHmacAlgorithm(kCCHmacAlgSHA256), $0.baseAddress, hmacKey.count)
                }
                var remaining = authLen
                while remaining > 0 {
                    let chunkSize = Int(min(UInt64(bufferSize), remaining))
                    let chunk = inFileHandle.readData(ofLength: chunkSize)
                    chunk.withUnsafeBytes { CCHmacUpdate(&hmacCtx, $0.baseAddress, chunk.count) }
                    remaining -= UInt64(chunk.count)
                }
                var computedTag = Data(count: StreamCryptor.hmacSize)
                computedTag.withUnsafeMutableBytes { CCHmacFinal(&hmacCtx, $0.baseAddress) }
                guard computedTag == storedHMAC else { return nil }   // tampered or wrong password

                // Pass 2: decrypt ciphertext (from fileOffset up to fileSize-32)
                try inFileHandle.seek(toOffset: self.fileOffset)
                var cipherRemaining = fileSize - self.fileOffset - UInt64(StreamCryptor.hmacSize)
                var shouldLoop = true
                while shouldLoop {
                    autoreleasepool {
                        if cipherRemaining == 0 {
                            let plainText = self.final()
                            outFileHandle.write(plainText)
                            shouldLoop = false
                        } else {
                            let chunkSize = Int(min(UInt64(bufferSize), cipherRemaining))
                            let data = inFileHandle.readData(ofLength: chunkSize)
                            let plainText = self.update(with: data)
                            outFileHandle.write(plainText)
                            cipherRemaining -= UInt64(data.count)
                        }
                    }
                }
                return self.status == CCCryptorStatus(kCCSuccess) ? outputLocation : nil
            }
        } catch {
            print("Error opening file handles: \(error)")
            return nil
        }
    }
    
    /// Updates the output file with the given data
    /// - Parameter data: the data to encrypt/decrypt
    /// - Returns: the data after passing it through the encryption/decryption operation
    private func update(with data: Data) -> Data {
        var outData = Data(count: data.count)
        let outDataCount = outData.count
        var numBytesUpdated = 0
        data.withUnsafeBytes { dataPtr in
            outData.withUnsafeMutableBytes { outDataPtr in
                self.status = CCCryptorUpdate(cryptorRef.pointee, dataPtr, data.count, outDataPtr.baseAddress!, outDataCount, &numBytesUpdated)
            }
        }
        /* For debugging: */
        // print("Cryptor status: \(self.status == kCCSuccess ? "Good" : "\(self.status)") \(numBytesUpdated)")
        return Data(outData[..<numBytesUpdated])
    }
    
    /// Finalizes the encryption/decryption
    /// - Returns: the final data to write to the output file
    private func final() -> Data {
        var outData = Data(count: kCCKeySizeAES256)
        let outDataCount = outData.count
        var amountBufFilled = 0
        outData.withUnsafeMutableBytes { outDataPtr in
            self.status = CCCryptorFinal(cryptorRef.pointee, outDataPtr, outDataCount, &amountBufFilled)
        }
        /* For debugging: */
        // print("Cryptor status at completion: \(self.status == kCCSuccess ? "Good" : "\(self.status)") \(amountBufFilled)")
        return Data(outData[..<amountBufFilled])
    }
    
    /// Pack new file with data for later decryption
    /// - Returns: the header bytes written, used as HMAC additional data
    @discardableResult
    private func packFile(into handle: FileHandle, preEncryptionNameAndExtension: String) throws -> Data {
        guard let fileNameAndExtension = preEncryptionNameAndExtension.data(using: .utf8) else {
            throw CryptoError(status: CCStatus(kCCUnspecifiedError))
        }
        // since .utf8 takes 1-4 bytes per character using a UInt16 puts the upper lim at ~16k characters. I'd use a UInt8 but that would leave a max of 63 characters which could reasonably be exceeded by a filename + extension. Calculated with max_size/4
        var length = UInt16(fileNameAndExtension.count)
        let lengthData = Data(bytes: &length, count: MemoryLayout<UInt16>.size)
        var header = Data(StreamCryptor.magicV2)
        for dataItem in [self.salt, self.iv, lengthData, fileNameAndExtension] {
            header.append(dataItem)
        }
        handle.write(header)
        return header
    }
    
    /// Unpacks the necessary data from an encrypted file
    /// This method assumes that the calling method has correctly set up the FileHandle for access
    /// - Parameter fileLocation : the location of the file to unpack
    /// - Returns: a struct with all the unpacked data
    private func unpackEncryptedFile(atLocation fileLocation: URL) -> UnpackedFile? {
        guard fileLocation.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer {
            fileLocation.stopAccessingSecurityScopedResource()
        }
        do {
            let handle = try FileHandle(forReadingFrom: fileLocation)
            defer {
                handle.closeFile()
            }
            // Verify magic header — reject old-format or non-iCryptr files
            let magic = handle.readData(ofLength: 4)
            guard magic == Data(StreamCryptor.magicV2) else { return nil }
            let salt = handle.readData(ofLength: 64)
            let iv = handle.readData(ofLength: kCCBlockSizeAES128)
            guard let fileNameAndTypeLenData = try handle.read(upToCount: 2) else {
                return nil
            }
            let fileNameAndTypeLen = try fileNameAndTypeLenData.withUnsafeBytes<UInt16>() { rawPtr -> UInt16 in
                return rawPtr.load(as: UInt16.self)
            }
            guard let rawFileNameAndTypeData = try handle.read(upToCount: Int(fileNameAndTypeLen)) else {
                return nil
            }
            let fileNameAndTypeData = String(decoding: rawFileNameAndTypeData, as: UTF8.self)
            let fileDataOffset = try handle.offset()
            // Read HMAC tag from end of file
            let fileSize = handle.seekToEndOfFile()
            try handle.seek(toOffset: fileSize - UInt64(StreamCryptor.hmacSize))
            let storedHMAC = handle.readData(ofLength: StreamCryptor.hmacSize)
            return UnpackedFile(iv: iv, salt: salt, fileNameAndTypeData: fileNameAndTypeData,
                                fileDataOffset: fileDataOffset, storedHMAC: storedHMAC)

        } catch {
            print("Error opening file handles: \(error)")
            return nil
        }

    }
}

