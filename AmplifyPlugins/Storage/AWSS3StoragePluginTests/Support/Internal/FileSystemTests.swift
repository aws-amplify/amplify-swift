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

    func testGeneratingZeroByes() throws {
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
            try fs.createFile(baseURL: directoryURL, filename: name, data: data)
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
            Array(repeating: "a", count: 5_120).joined(),
            Array(repeating: "b", count: 5_120).joined(),
            Array(repeating: "c", count: 5_120).joined(),
            Array(repeating: "d", count: 5_120).joined(),
            Array(repeating: "e", count: 5_120).joined(),
            Array(repeating: "f", count: 2_560).joined()
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

        var rebuild: [String] = []

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

                    rebuild.append(fileContents)
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
            } else {
                exp.fulfill()
            }
        }

        step?(0)

        wait(for: [exp], timeout: 60.0)

        print("")

        XCTAssertGreaterThan(parts.count, 0)
        XCTAssertGreaterThan(rebuild.count, 0)
        XCTAssertEqual(parts.count, rebuild.count)
        XCTAssertEqual(parts, rebuild)
    }

}
