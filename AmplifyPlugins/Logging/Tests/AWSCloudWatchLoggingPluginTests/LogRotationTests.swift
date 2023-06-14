//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class LogRotationTests: XCTestCase {
    
    var systemUnderTest: LogRotation!
    var directory: URL!
    var fileCountLimit = 3
    var fileSizeLimitInBytes = UInt64(1024)

    override func setUp() async throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        systemUnderTest = try LogRotation(directory: directory,
                                          fileCountLimit: fileCountLimit,
                                          fileSizeLimitInBytes: fileSizeLimitInBytes)
    }
    
    override func tearDown() async throws {
        systemUnderTest = nil
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }
    
    func testDefaultState() throws {
        XCTAssertEqual(systemUnderTest.currentLogFile.available, systemUnderTest.currentLogFile.sizeLimitInBytes)
        XCTAssertEqual(systemUnderTest.currentLogFile.fileURL.lastPathComponent, "amplify.0.log")
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(contents.map { $0.lastPathComponent }, [
            "amplify.0.log"
        ])
    }
    
    func testInitializeWithNonEmptyDirectory() throws {
        let originalContents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(originalContents.map { $0.lastPathComponent }, [
            "amplify.0.log"
        ])

        systemUnderTest = try LogRotation(directory: directory,
                                          fileCountLimit: fileCountLimit,
                                          fileSizeLimitInBytes: fileSizeLimitInBytes)
        XCTAssertEqual(systemUnderTest.currentLogFile.fileURL.lastPathComponent, "amplify.1.log")
        try systemUnderTest.rotate()
        
        let rotatedContents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(rotatedContents.map { $0.lastPathComponent }, [
            "amplify.2.log",
            "amplify.1.log",
            "amplify.0.log",
        ])
        
        systemUnderTest = try LogRotation(directory: directory,
                                          fileCountLimit: fileCountLimit,
                                          fileSizeLimitInBytes: fileSizeLimitInBytes)
        XCTAssertEqual(systemUnderTest.currentLogFile.fileURL.lastPathComponent, "amplify.0.log")
    }
    
    func testRotateEmptyAll() async throws {
        for _ in 0..<(fileCountLimit) {
            XCTAssertEqual(systemUnderTest.currentLogFile.available, systemUnderTest.currentLogFile.sizeLimitInBytes)
            try systemUnderTest.rotate()
            try await Task.sleep(seconds: 0.10)
        }
        let allFiles = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(Set(allFiles.map { $0.lastPathComponent }), Set([
            "amplify.0.log",
            "amplify.1.log",
            "amplify.2.log",
        ]))
    }
    
    func testRotateToUnderutilized() async throws {
        let bytes = (0..<systemUnderTest.currentLogFile.sizeLimitInBytes).map { _ in UInt8.random(in: 0..<255) }
        let largeData = Data(bytes)
        let tinyData = Data([1, 2, 3, 4])
        
        // Fill-up all files except for the one at index 3
        let chosenIndex = 1
        for index in 0..<(fileCountLimit) {
            if (index != chosenIndex) {
                try systemUnderTest.currentLogFile.write(data: largeData)
            } else {
                try systemUnderTest.currentLogFile.write(data: tinyData)
            }
            try systemUnderTest.rotate()
            try await Task.sleep(seconds: 0.10)
        }
        
        // The last rotation should result in currentLogFile being the one at the chosen index.
        XCTAssertEqual(systemUnderTest.currentLogFile.fileURL.lastPathComponent, "amplify.\(chosenIndex).log")
        let contents = FileManager.default.contents(atPath: systemUnderTest.currentLogFile.fileURL.path)
        XCTAssertEqual(contents, tinyData)
    }
    
    func testRotateToOldestLastModified() async throws {
        let bytes = (0..<systemUnderTest.currentLogFile.sizeLimitInBytes).map { _ in UInt8.random(in: 0..<255) }
        let data = Data(bytes)
        
        for _ in 0..<(fileCountLimit) {
            try systemUnderTest.currentLogFile.write(data: data)
            try systemUnderTest.rotate()
            try await Task.sleep(seconds: 0.10)
        }
        
        // The last rotation should result in currentLogFile being one with the last modified date.
        XCTAssertEqual(systemUnderTest.currentLogFile.fileURL.lastPathComponent, "amplify.0.log")
    }
    
    func testBogusFileCountLimit() throws {
        do {
            _ = try LogRotation(directory: directory, fileCountLimit: 0, fileSizeLimitInBytes: 0)
            XCTFail("Expecting failure when initializing with fileCountLimit=0")
        } catch {
            XCTAssertEqual(String(describing: error), "invalidFileCountLimit(0)")
        }
        do {
            _ = try LogRotation(directory: directory, fileCountLimit: 1, fileSizeLimitInBytes: 0)
            XCTFail("Expecting failure when initializing with fileCountLimit=1")
        } catch {
            XCTAssertEqual(String(describing: error), "invalidFileCountLimit(1)")
        }
    }
    
    func testBogusFileSizeLimitInBytes() throws {
        for fileSizeLimitInBytes in 0..<LogRotation.minimumFileSizeLimitInBytes {
            do {
                _ = try LogRotation(directory: directory,
                                    fileCountLimit: 2,
                                    fileSizeLimitInBytes: UInt64(fileSizeLimitInBytes))
                XCTFail("Expecting failure when initializing with fileCountLimit=\(fileSizeLimitInBytes)")
                break
            } catch {
                XCTAssertEqual(String(describing: error), "invalidFileSizeLimitInBytes(\(fileSizeLimitInBytes))")
            }
        }
    }
}
