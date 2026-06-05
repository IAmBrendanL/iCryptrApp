//
//  StreamCryptorHMACTests.swift
//  iCryptr
//
//  Verifies that StreamCryptor's HMAC-SHA256 authentication catches
//  tampering with any byte of an .icryptr file (header or ciphertext) and
//  rejects wrong passwords before any plaintext is written.
//
//

import XCTest
import CommonCrypto
@testable import iCryptr

final class StreamCryptorHMACTests: XCTestCase {

    private let password = "TestPass!2345"
    private var workDir: URL!
    /// StreamCryptor writes outputs into the app/test-bundle Documents dir;
    /// we collect every URL it produces so tearDown can clean them up.
    private var outputsToClean: [URL] = []

    override func setUpWithError() throws {
        workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("iCryptrHMACTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir,
                                                withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: workDir)
        for url in outputsToClean {
            try? FileManager.default.removeItem(at: url)
        }
        outputsToClean.removeAll()
    }

    // MARK: - Positive case

    /// Encrypt → decrypt with the right password must return the original bytes.
    /// If this fails, every other test in this file is meaningless.
    func testRoundTripSucceeds() throws {
        let original = Data((0..<8192).map { UInt8($0 & 0xff) })
        let plaintextURL = try makePlaintext(original)
        let encryptedURL = try encrypt(plaintextURL, outputBase: "rt-out")

        let decryptedURL = try XCTUnwrap(
            attemptDecrypt(encryptedURL, password: password),
            "decrypt returned nil for a valid file"
        )
        XCTAssertEqual(try Data(contentsOf: decryptedURL), original,
                       "decrypted bytes do not match original")
    }

    // MARK: - Authentication failures

    /// Wrong password yields a different HMAC key, so verification fails
    /// before pass-2 decryption runs.
    func testWrongPasswordRejected() throws {
        let plaintextURL = try makePlaintext(Data("hello".utf8))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "wp-out")

        XCTAssertNil(attemptDecrypt(encryptedURL, password: "WrongPass!9999"),
                     "wrong password must fail HMAC verification")
    }

    /// Flipping a byte inside the trailing 32-byte HMAC tag must be detected.
    func testTamperedHMACTagRejected() throws {
        let plaintextURL = try makePlaintext(Data("hello".utf8))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "tag-out")

        let size = try fileSize(of: encryptedURL)
        try flipBit(at: size - 1, in: encryptedURL)   // last byte of HMAC tag

        XCTAssertNil(attemptDecrypt(encryptedURL, password: password),
                     "flipped HMAC tag must be rejected")
    }

    /// Flipping a ciphertext byte (not the tag, not the header) must be detected.
    /// Uses a 256-byte payload so we can flip a byte safely inside ciphertext
    /// without overlapping the tag or header.
    func testTamperedCiphertextRejected() throws {
        let plaintextURL = try makePlaintext(Data(repeating: 0x41, count: 256))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "ct-out")

        let size = try fileSize(of: encryptedURL)
        // 64 bytes from EOF → past the 32-byte tag, inside the ciphertext.
        try flipBit(at: size - 64, in: encryptedURL)

        XCTAssertNil(attemptDecrypt(encryptedURL, password: password),
                     "flipped ciphertext byte must be rejected by HMAC")
    }

    /// Filename IV lives at offsets 68..84 (immediately after the salt).
    /// Flipping a bit here would otherwise corrupt the first CBC block of the
    /// encrypted filename — the value of this test is confirming the HMAC
    /// covers the *header*, not just the body.
    func testTamperedNameIVRejected() throws {
        let plaintextURL = try makePlaintext(Data("hello world".utf8))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "niv-out")

        try flipBit(at: 70, in: encryptedURL)   // mid-nameIV

        XCTAssertNil(attemptDecrypt(encryptedURL, password: password),
                     "flipped filename-IV byte must be rejected by HMAC")
    }

    /// File-body IV moved past the encrypted-name region. For an input named
    /// `plain.bin` (9 bytes) the PKCS7-padded encrypted name is 16 bytes, so
    /// the body IV starts at offset 4 + 64 + 16 + 2 + 16 = 102 (mid-IV ≈ 110).
    func testTamperedBodyIVRejected() throws {
        let plaintextURL = try makePlaintext(Data("hello world".utf8))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "biv-out")

        try flipBit(at: 110, in: encryptedURL)   // inside file-body IV

        XCTAssertNil(attemptDecrypt(encryptedURL, password: password),
                     "flipped body-IV byte must be rejected by HMAC")
    }

    /// Salt lives at offsets 4..68 (unchanged). Flipping the salt also derives
    /// a different key on decrypt, so this is doubly-rejected — but the HMAC
    /// catches it first, which is what we care about.
    func testTamperedSaltRejected() throws {
        let plaintextURL = try makePlaintext(Data("hello world".utf8))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "salt-out")

        try flipBit(at: 10, in: encryptedURL)

        XCTAssertNil(attemptDecrypt(encryptedURL, password: password),
                     "flipped salt byte must be rejected")
    }

    /// Flipping a byte inside the encrypted-filename region (offset 86, just
    /// past name length) must be detected by HMAC, even though that region is
    /// also ciphertext that decrypts to a plausible-looking name.
    func testTamperedEncryptedNameRejected() throws {
        let plaintextURL = try makePlaintext(Data("hello world".utf8))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "name-out")

        try flipBit(at: 88, in: encryptedURL)   // inside encrypted-name region

        XCTAssertNil(attemptDecrypt(encryptedURL, password: password),
                     "flipped encrypted-filename byte must be rejected by HMAC")
    }

    /// The original filename must not appear in cleartext anywhere in the
    /// encrypted file. This is the core privacy guarantee of the format
    /// change — the name is now ciphertext, not plaintext header data.
    func testFilenameNotInCleartext() throws {
        let secretName = "secret-leak-marker-\(UUID().uuidString).txt"
        let plaintextURL = try makePlaintext(Data("payload".utf8), name: secretName)
        let encryptedURL = try encrypt(plaintextURL, outputBase: "privacy-out")

        let encryptedBytes = try Data(contentsOf: encryptedURL)
        let nameBytes = Data(secretName.utf8)
        XCTAssertNil(encryptedBytes.range(of: nameBytes),
                     "original filename must not appear in cleartext in encrypted output")
    }

    /// Truncating the file shortens the HMAC tag (or removes ciphertext that
    /// the original tag covered) — verification must fail.
    func testTruncatedFileRejected() throws {
        let plaintextURL = try makePlaintext(Data("hello world".utf8))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "trunc-out")

        let size = try fileSize(of: encryptedURL)
        let handle = try FileHandle(forUpdating: encryptedURL)
        try handle.truncate(atOffset: size - 1)
        try handle.close()

        XCTAssertNil(attemptDecrypt(encryptedURL, password: password),
                     "truncated file must fail HMAC verification")
    }

    /// Flipping the magic version byte makes `unpackEncryptedFile` reject the
    /// file before we ever construct the Cryptor — confirms the early reject
    /// path that runs before HMAC verification.
    func testMagicVersionByteRejected() throws {
        let plaintextURL = try makePlaintext(Data("hello".utf8))
        let encryptedURL = try encrypt(plaintextURL, outputBase: "magic-out")

        try flipBit(at: 3, in: encryptedURL)   // version byte

        let cryptor = try? StreamCryptor(fileLoc: encryptedURL,
                                         forOperation: .decrypt,
                                         withPassword: password)
        XCTAssertNil(cryptor,
                     "wrong magic byte must reject the file at init time")
    }

    // MARK: - Helpers

    private func makePlaintext(_ bytes: Data,
                               name: String = "plain.bin") throws -> URL {
        let url = workDir.appendingPathComponent(name)
        try bytes.write(to: url)
        return url
    }

    /// Encrypts `plaintextURL` and tracks the produced file for cleanup.
    private func encrypt(_ plaintextURL: URL, outputBase: String) throws -> URL {
        let cryptor = try StreamCryptor(fileLoc: plaintextURL,
                                        forOperation: .encrypt,
                                        withPassword: password)
        let out = try XCTUnwrap(cryptor.cryptFile(newName: outputBase),
                                "encrypt returned nil")
        outputsToClean.append(out)
        return out
    }

    /// Returns the decrypted output URL, or nil if init or HMAC verification
    /// fails. Tracks any produced file for cleanup.
    private func attemptDecrypt(_ ciphertextURL: URL, password: String) -> URL? {
        guard let cryptor = try? StreamCryptor(fileLoc: ciphertextURL,
                                                forOperation: .decrypt,
                                                withPassword: password) else {
            return nil
        }
        let result = cryptor.cryptFile(newName: nil)
        if let url = result { outputsToClean.append(url) }
        return result
    }

    /// XORs the low bit of a single byte at `offset` in `fileURL`.
    private func flipBit(at offset: UInt64, in fileURL: URL) throws {
        let handle = try FileHandle(forUpdating: fileURL)
        defer { try? handle.close() }
        try handle.seek(toOffset: offset)
        var byte = handle.readData(ofLength: 1)
        XCTAssertEqual(byte.count, 1, "could not read byte at offset \(offset)")
        byte[0] ^= 0x01
        try handle.seek(toOffset: offset)
        try handle.write(contentsOf: byte)
    }

    private func fileSize(of url: URL) throws -> UInt64 {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attrs[.size] as? UInt64 { return size }
        if let size = attrs[.size] as? Int { return UInt64(size) }
        return 0
    }
}
