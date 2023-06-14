//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class LogActorTests: XCTestCase {
    
    let fileCountLimit = 7
    let fileSizeLimitInBytes = UInt64(1024)
    
    var systemUnderTest: LogActor!
    var directory: URL!
    var rotations: [URL]!
    var subscription: Combine.Cancellable! { willSet { subscription?.cancel()} }
    
    override func setUp() async throws {
        rotations = []
        directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        systemUnderTest = try LogActor(directory: directory,
                                       fileCountLimit: fileCountLimit,
                                       fileSizeLimitInBytes: fileSizeLimitInBytes)
        subscription = await systemUnderTest.rotationPublisher().sink { [weak self] url in
            self?.rotations.append(url)
        }
    }
    
    override func tearDown() async throws {
        systemUnderTest = nil
        subscription = nil
        rotations = nil
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }
    
    func testRecord() async throws {
        XCTAssertEqual(rotations, [])
        
        let entry = LogEntry(tag: "LogActorTests", level: .error, message: UUID().uuidString, created: .init(timeIntervalSince1970: 0))
        try await systemUnderTest.record(entry)
        try await systemUnderTest.synchronize()
        
        XCTAssertEqual(rotations, [])
        
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let fileURL = try XCTUnwrap(files.first)
        let contents = try XCTUnwrap(FileManager.default.contents(atPath: fileURL.path))
        let decoded = try LogEntryCodec().decode(data: contents)
        XCTAssertEqual(decoded, entry)
    }
    
    func testRecordToTriggerRotation() async throws {
        XCTAssertEqual(rotations, [])
        
        let size = try LogEntry.minimumSizeForLogEntry(level: .error)
        let numberOfEntries = Int(fileSizeLimitInBytes/UInt64(size)) + 1
        let entries = (0..<numberOfEntries).map { LogEntry(tag: "", level: .error, message: "\($0)", created: .init(timeIntervalSince1970: Double($0))) }
        for entry in entries {
            try await systemUnderTest.record(entry)
        }
        try await systemUnderTest.synchronize()
        
        XCTAssertEqual(rotations.count, 1)
        XCTAssertEqual(rotations.map { $0.lastPathComponent }, [
            "amplify.0.log",
        ])
        
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let fileNames = files.map { $0.lastPathComponent }
        XCTAssertEqual(fileNames.sorted(), [
            "amplify.0.log",
            "amplify.1.log",
        ])
        let decoded = try files.flatMap { fileURL in
            let codec = LogEntryCodec()
            return try codec.decode(from: fileURL)
        }
        XCTAssertEqual(decoded.sorted(), entries.sorted())
    }
}
