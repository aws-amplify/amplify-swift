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
    var fileCountLimit = 5
    var fileSizeLimitInBytes = 1024

    override func setUp() async throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        systemUnderTest = try LogRotation(directory: directory,
                                          fileSizeLimitInBytes: fileSizeLimitInBytes)
    }
    
    override func tearDown() async throws {
        systemUnderTest = nil
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }
    
    /// Given: a log rotation
    /// When: the current log file is access
    /// Then: the log file default to ampliyf.0.log
    func testLogRotationDefaultState() throws {
        XCTAssertEqual(systemUnderTest.currentLogFile.available, systemUnderTest.currentLogFile.sizeLimitInBytes)
        XCTAssertEqual(systemUnderTest.currentLogFile.fileURL.lastPathComponent, "amplify.0.log")
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(contents.map { $0.lastPathComponent }, [
            "amplify.0.log"
        ])
    }
    
    /// Given: a log rotation
    /// When: a rotation occurs
    /// Then: then a new rotated log file is created
    func testLogRotationCreatesNewFiles() throws {
        let originalContents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(originalContents.map { $0.lastPathComponent }, [
            "amplify.0.log"
        ])

        systemUnderTest = try LogRotation(directory: directory,
                                          fileSizeLimitInBytes: fileSizeLimitInBytes)
        XCTAssertEqual(systemUnderTest.currentLogFile.fileURL.lastPathComponent, "amplify.1.log")
        try systemUnderTest.rotate()
        
        var rotatedContents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(rotatedContents.map { $0.lastPathComponent }, [
            "amplify.2.log",
            "amplify.1.log",
            "amplify.0.log",
        ])
        
        try systemUnderTest.rotate()
        rotatedContents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(rotatedContents.map { $0.lastPathComponent }, [
            "amplify.2.log",
            "amplify.3.log",
            "amplify.1.log",
            "amplify.0.log",
        ])
        
        try systemUnderTest.rotate()
        rotatedContents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(rotatedContents.map { $0.lastPathComponent }, [
            "amplify.4.log",
            "amplify.2.log",
            "amplify.3.log",
            "amplify.1.log",
            "amplify.0.log",
        ])
        
        systemUnderTest = try LogRotation(directory: directory,
                                          fileSizeLimitInBytes: fileSizeLimitInBytes)
        XCTAssertEqual(systemUnderTest.currentLogFile.fileURL.lastPathComponent, "amplify.0.log")
    }
    
    /// Given: a log rotation
    /// When: rotation occurs to the max limit
    /// Then: the log rotation circles back to 0
    func testLogRotationToMaxLimit() async throws {
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
            "amplify.3.log",
            "amplify.4.log"
        ]))
    }
    
    func testLogRotationUseUnderutilizedLogFile() async throws {
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
    
    func testLogRotationUsesOldestLastModifiedLogFile() async throws {
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
    
    func testLogRotationThrowsErrorWithInvalidFileSizeLimitInBytes() throws {
        for fileSizeLimitInBytes in 0..<LogRotation.minimumFileSizeLimitInBytes {
            do {
                _ = try LogRotation(directory: directory,
                                    fileSizeLimitInBytes: fileSizeLimitInBytes)
                XCTFail("Expecting failure when initializing with fileCountLimit=\(fileSizeLimitInBytes)")
                break
            } catch {
                XCTAssertEqual(String(describing: error), "invalidFileSizeLimitInBytes(\(fileSizeLimitInBytes))")
            }
        }
    }
}
