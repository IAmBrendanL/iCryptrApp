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


struct CryptorOperations {
    func Encrypt() -> CCOperation {
        return CCOperation(kCCEncrypt)
    }
    func Decrypt() -> CCOperation{
        return CCOperation(kCCDecrypt)
    }
}

class StreamCryptor {
    /*
     The purpose of this class is to make it so that I can encapsulte all the things related to streaming a file.
     I want to be able to hand it a file descriptor and then chunk it and send it to the algorithm and get the updated
     file out.
     ,
     Now in terms of making certain this works I still need to use my custom method of looking at things. I will need
     to save files in the .iCryptr format. I could look at how cryptoswift handles things and do it that way...
     I could also try and make this just a thing in that respect.
     */
    
    fileprivate var status: CCCryptorStatus
    private let cryptorRef = UnsafeMutablePointer<CCCryptorRef?>.allocate(capacity: 1)
    private var buffer = Data()
    
    /// Takes initializes an encryption or decryption operation.
    /// - Parameters:
    fileprivate init(operation: CCOperation, keyBuffer: UnsafeRawPointer, keySize: Int, ivBuffer: UnsafeRawPointer) throws {
        let status = CCCryptorCreate(operation, CCAlgorithm(kCCAlgorithmAES),
                                     CCOptions(kCCOptionPKCS7Padding),
                                     keyBuffer, keySize,
                                     ivBuffer, cryptorRef)
        self.status = status
        // TODO: Do error handling
    }
    
    deinit {
        let _ = CCCryptorRelease(cryptorRef.pointee)
        // if status != kCCSuccess {
        // }
        cryptorRef.deallocate()
    }
       
    fileprivate func update(inPtr: UnsafeRawPointer, inDataLen: Int, outPtr: UnsafeMutableRawPointer, outBufSpace: Int,
                       outDataSize: inout Int) -> CCCryptorStatus {
        if self.status == kCCSuccess {
            self.status = CCCryptorUpdate(cryptorRef.pointee, inPtr, inDataLen, outPtr, outBufSpace, &outDataSize)
        }
        return self.status
    }
    
    fileprivate func final(outPtr: UnsafeMutableRawPointer, outBufSize: Int, amountBufFilled: inout Int) -> CCCryptorStatus {
        if self.status == kCCSuccess {
            self.status = CCCryptorFinal(cryptorRef.pointee, outPtr, outBufSize, &amountBufFilled)
        }
        return self.status
    }
    
}


/// Wraps the StreamCryptor using swift primatives
class SwiftStreamCryptor {
    private let operation: CCOperation
    private let cryptr: StreamCryptor
    private let fileLocation: URL
    
    public init(fileLoc: URL, forOperation: CCOperation, withKey key: Data, andIV iv: Data) {
        fileLocation = fileLoc
        operation = forOperation
        cryptr = {
            key.withUnsafeBytes { keyPtr in
                iv.withUnsafeBytes { ivPtr in
                    //TODO fix
                    return try! StreamCryptor(operation: forOperation, keyBuffer: keyPtr, keySize: key.count, ivBuffer: ivPtr)
                }
            }
        }()
    }
    
    /// Encrypt or Decrypt the file given to the stream cryptor and output to the given location
    /// - Parameter outputLocation: The location to write the file to
    public func cryptFile(outputLocation: URL) {
        guard let inStream = InputStream(url: fileLocation) else {
            print("Couldn't open input stream at: \(fileLocation)")
            return
        }
        guard let outStream = OutputStream(url: outputLocation, append: true) else {
            print("Couldn't open output stream at: \(fileLocation)")
            return
        }
        defer {
            inStream.close()
            outStream.close()
        }
        let buf = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>.allocate(capacity: 524288008)
        while inStream.hasBytesAvailable {
            let len = inStream.read(buf, maxLength: 52428800)
            if len > 0 {
                let cypherText = self.update(with: Data(bytes: buf, count: len))
                // TODO Handle gracefully
                try! outStream.write(cypherText)
            } else if len == 0 {
                let cypherText = self.final()
                // TODO Handle gracefully
                try! outStream.write(cypherText)
            }
        }
    }
    
    public func update(with data: Data) -> Data {
        var outData = Data(count: data.count)
        let outDataCount = outData.count
        var numBytesUpdated = 0
        data.withUnsafeBytes { dataPtr in
            outData.withUnsafeMutableBytes { outDataPtr in
                cryptr.update(inPtr: dataPtr, inDataLen: data.count, outPtr: outDataPtr.baseAddress!, outBufSpace: outDataCount, outDataSize: &numBytesUpdated )
            }
        }
        print("Cryptor status: \(cryptr.status == kCCSuccess ? "Good" : "\(cryptr.status)") \(numBytesUpdated)")
        return Data(outData[..<numBytesUpdated])
    }
    
    public func final() -> Data {
        var outData = Data(count: kCCKeySizeAES256)
        let outDataCount = outData.count
        var numBytesUpdated = 0
        outData.withUnsafeMutableBytes { outDataPtr in
            cryptr.final(outPtr: outDataPtr, outBufSize: outDataCount, amountBufFilled: &numBytesUpdated)
        }
        print("Cryptor status at completion: \(cryptr.status == kCCSuccess ? "Good" : "\(cryptr.status)") \(numBytesUpdated)")
        return Data(outData[..<numBytesUpdated])
    }
    
}

