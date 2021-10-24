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
    fileprivate let cryptorRef = UnsafeMutablePointer<CCCryptorRef?>.allocate(capacity: 1)
    fileprivate var buffer = Data()
    
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
    fileprivate let cryptrData: Data
    fileprivate let operation: CCOperation
    fileprivate let cryptr: StreamCryptor
    
    public init(inData: Data, forOperation: CCOperation, withKey key: Data, andIV iv: Data) {
        cryptrData = inData
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
        
    
    public func update(with data: Data) -> Data {
        var outData = Data(count: kCCKeySizeAES256)
        let outDataCount = outData.count
        var numBytesUpdated = 0
        data.withUnsafeBytes { dataPtr in
            outData.withUnsafeMutableBytes { outDataPtr in
                cryptr.update(inPtr: dataPtr, inDataLen: data.count, outPtr: outDataPtr.baseAddress!, outBufSpace: outDataCount, outDataSize: &numBytesUpdated )
            }
        }
        return outData
    }
    
    public func final() -> Data {
        var outData = Data(count: kCCKeySizeAES256)
        let outDataCount = outData.count
        var numBytesUpdated = 0
        outData.withUnsafeMutableBytes { outDataPtr in
            cryptr.final(outPtr: outDataPtr, outBufSize: outDataCount, amountBufFilled: &numBytesUpdated)
        }
        outData.count = numBytesUpdated 
        return outData
    }
    
}

