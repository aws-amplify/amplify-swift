//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable identifier_name

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

extension FileSystem {

    /// Generates random bytes
    /// - Parameter bytes: bytes
    /// - Returns: random data
    func randomData(bytes: Bytes) -> Data {
        let count = bytes.bytes
        var bytes = [Int8](repeating: 0, count: count)
        // Fill bytes with secure random data
        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            count,
            &bytes
        )
        // A status of errSecSuccess indicates success
        guard status == errSecSuccess else {
            Fatal.error("Failed to copy bytes: \(status)")
        }
        let data = Data(bytes: bytes, count: count)
        return data
    }

}

extension Bytes {
    /// Generates random data with the number of bytes for this instance
    /// - Returns: random data
    func generateRandomData() -> Data {
        FileSystem.default.randomData(bytes: self)
    }
}

class FileSystemTests: XCTestCase {

    func testFileExists() throws {
        let fs = FileSystem()
        let directoryURL = fs.createTemporaryDirectoryURL()
        try fs.createDirectory(at: directoryURL)
        let bytes = Bytes.megabytes(3)
        let data = bytes.generateRandomData()
        let fileURL = try fs.createTemporaryFile(data: data, baseURL: directoryURL)
        defer {
            fs.removeDirectoryIfExists(directoryURL: directoryURL)
        }
        XCTAssertTrue(fs.fileExists(atURL: fileURL))
    }

    func testFileContents() throws {
        let fs = FileSystem()
        let directoryURL = fs.createTemporaryDirectoryURL()
        try fs.createDirectory(at: directoryURL)
        let bytes = Bytes.megabytes(3)
        let data = bytes.generateRandomData()
        let fileURL = try fs.createTemporaryFile(data: data, baseURL: directoryURL)
        defer {
            fs.removeDirectoryIfExists(directoryURL: directoryURL)
        }
        guard let contents = fs.contents(atURL: fileURL) else {
            XCTFail("Contents did not load")
            return
        }
        XCTAssertEqual(data.count, contents.count)
        XCTAssertEqual(data, contents)
    }

    func testGetFileSize() throws {
        let fs = FileSystem()
        let directoryURL = fs.createTemporaryDirectoryURL()
        try fs.createDirectory(at: directoryURL)
        let bytes = Bytes.megabytes(3)
        let data = bytes.generateRandomData()
        let fileURL = try fs.createTemporaryFile(data: data, baseURL: directoryURL)
        defer {
            fs.removeDirectoryIfExists(directoryURL: directoryURL)
        }
        let size = fs.getFileSize(fileURL: fileURL)

        XCTAssertEqual(UInt64(bytes.bytes), size)
    }

    func testGeneratingZeroBytes() throws {
        let fs = FileSystem()
        let bytes = Bytes.bytes(0)
        let data = fs.randomData(bytes: bytes)
        XCTAssertEqual(0, data.count)
    }

    func testDirectoryContents() throws {
        let fs = FileSystem()
        let directoryURL = fs.createTemporaryDirectoryURL()
        try fs.createDirectory(at: directoryURL)
        let names = ["one.dat", "two.dat", "three.dat"]
        let data = Bytes.bytes(5).generateRandomData()
        for name in names {
            _ = try fs.createFile(baseURL: directoryURL, filename: name, data: data)
        }
        let contents = try fs.directoryContents(directoryURL: directoryURL, matching: { $0.hasSuffix(".dat") })
            .map {
                $0.lastPathComponent
            }
        XCTAssertEqual(names.count, contents.count)
        for name in names {
            XCTAssertTrue(contents.contains(name))
        }
    }

    func testCreatingPartialFile() throws {
        let exp = expectation(description: #function)

        let parts: [String] = [
            Array(repeating: "a", count: 64).joined(),
            Array(repeating: "b", count: 64).joined(),
            Array(repeating: "c", count: 64).joined(),
            Array(repeating: "d", count: 64).joined(),
            Array(repeating: "e", count: 64).joined(),
            Array(repeating: "f", count: 64).joined()
        ]
        let string = parts.joined()

        let fs = FileSystem()

        guard let data = string.data(using: .utf8) else {
            XCTFail("Failed to create data for file")
            return
        }
        let fileURL = try fs.createTemporaryFile(data: data)
        defer {
            fs.removeFileIfExists(fileURL: fileURL)
        }
        var offset = 0
        var step: ((Int) -> Void)?
        let queue = DispatchQueue(label: "done-count-queue")

        var rebuild: [String] = [] {
            didSet {
                if parts.count == rebuild.count {
                    exp.fulfill()
                }
            }
        }

        let createPartialFile = { (index: Int) in
            let part = parts[index]

            print("Creating partial file [\(index)]")
            fs.createPartialFile(fileURL: fileURL, offset: offset, length: part.count) { result in
                do {
                    let partFileURL = try result.get()
                    let fileContents = try String(contentsOf: partFileURL)
                    let partContents = parts[index]
                    XCTAssertEqual(fileContents, partContents)
                    XCTAssertEqual(fileContents.first, fileContents.last)
                    XCTAssertEqual(partContents.first, partContents.last)
                    XCTAssertEqual(partContents.first, fileContents.last)
                    XCTAssertEqual(fileContents.first, partContents.last)

                    print("File Contents:\n\(fileContents)")

                    queue.sync {
                        rebuild.append(fileContents)
                    }
                } catch {
                    XCTFail("Failed to create partial file: \(error)")
                }
            }
            offset += part.count
            step?(index + 1)
        }

        step = { (index: Int) in
            if index < parts.count {
                createPartialFile(index)
            }
        }

        step?(0)

        wait(for: [exp], timeout: 5.0)

        XCTAssertGreaterThan(parts.count, 0)
        XCTAssertGreaterThan(rebuild.count, 0)
        XCTAssertEqual(parts.count, rebuild.count)
        XCTAssertEqual(parts, rebuild.sorted())
    }

    func testRemovingDirectoryWithoutContents() throws {
        let fs = FileSystem()
        let directoryURL = fs.createTemporaryDirectoryURL()
        try fs.createDirectory(at: directoryURL)
        XCTAssertTrue(fs.directoryExists(atURL: directoryURL))
        fs.removeDirectoryIfExists(directoryURL: directoryURL)
        XCTAssertFalse(fs.directoryExists(atURL: directoryURL))
    }

    func testRemovingDirectoryWithContents() throws {
        let fs = FileSystem()
        let directoryURL = fs.createTemporaryDirectoryURL()
        try fs.createDirectory(at: directoryURL)
        XCTAssertTrue(fs.directoryExists(atURL: directoryURL))

        // populate contents
        _ = try fs.createTemporaryFile(data: fs.randomData(bytes: .bytes(5)), baseURL: directoryURL)
        _ = try fs.createTemporaryFile(data: fs.randomData(bytes: .bytes(5)), baseURL: directoryURL)
        _ = try fs.createTemporaryFile(data: fs.randomData(bytes: .bytes(5)), baseURL: directoryURL)
        let subDirURL = directoryURL.appendingPathComponent("subdir")
        try fs.createDirectory(at: subDirURL)

        fs.removeDirectoryIfExists(directoryURL: directoryURL)
        XCTAssertFalse(fs.directoryExists(atURL: directoryURL))

    }

}
