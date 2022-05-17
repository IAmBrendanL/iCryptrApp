//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Brendan Lindsey on 8/17/21.
//

import XCTest
import CommonCrypto
@testable import iCryptr

class Tests_iOS: XCTestCase {
    
    let filename = "test.txt"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testFileEncryption() {
        // THE BELLOW WAS USED TO FIGURE OUT HOW TO WRITE THE CODE
        /*
        let service = FileStreamService()
        let fileLocation = URL(fileURLWithPath: "/Users/brendan/A New Hope.m4v")
//        let fileLocation = Bundle(for: Tests_iOS.self).resourceURL!.appendingPathComponent(filename)
        guard let stream = service.getFileStream(fromUrl: fileLocation) else {
            XCTFail("Couldn't open file stream at: \(fileLocation)")
            return
        }
//        guard let output = OutputStream(url: Bundle(for: Tests_iOS.self).resourceURL!.appendingPathComponent("output.iCryptr"), append: false) else  { return }
        guard let output = OutputStream(url: URL(fileURLWithPath: "/Users/brendan/output.iCryptr"), append: false) else  { return }
        guard let output2 = OutputStream(url: URL(fileURLWithPath: "/Users/brendan/output.txt"), append: false) else  { return }
        output.open()
        output2.open()
        stream.open()
        defer {
            stream.close()
            output.close()
            output2.close()
        }
        let buf = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>.allocate(capacity: 524288008)
        let pass = "test"
        guard let salt = "salt".data(using: .utf8) else {return}
        guard let IV = "iv".data(using: .utf8) else {return}
        let rounds = UInt32(100)
//        guard let salt = generateSaltForKeyGeneration() else { return }
//        let rounds = getKeyGenerationRounds(pass, salt)
//        guard let IV = generateIVForFileEncryption() else { return }
        guard let key = generateKeyFromPassword(pass, salt, rounds) else { return }
        let streamCryptor = SwiftStreamCryptor(forOperation: CCOperation(kCCEncrypt), withKey: key, andIV: IV)
        while stream.hasBytesAvailable {
            let len = stream.read(buf, maxLength: 52428800)
            if len > 0 {
                let stuff = streamCryptor.update(with: Data(bytes: buf, count: len))
                try! output.write(stuff)
            } else if len == 0 {
                let stuff = streamCryptor.final()
//                try! output.write(stuff)
                output.close()
            }
        }
        output.close()
        guard let stream2 = InputStream(url: URL(fileURLWithPath: "/Users/brendan/output.iCryptr")) else {
            XCTFail("Couldn't open file stream at: \(fileLocation)")
            return
        }
        defer {
            stream2.close()
        }
        stream2.open()
        let destreamCryptor = SwiftStreamCryptor(forOperation: CCOperation(kCCDecrypt), withKey: key, andIV: IV)
        while stream2.hasBytesAvailable {
            let len = stream2.read(buf, maxLength: 52428800)
            if len > 0 {
                let stuff = destreamCryptor.update(with: Data(bytes: buf, count: len))
                try! output2.write(stuff)
            } else if len == 0 {
                let stuff = destreamCryptor.final()
//                try! output2.write(stuff)
            }
        }
         */
    }
}
