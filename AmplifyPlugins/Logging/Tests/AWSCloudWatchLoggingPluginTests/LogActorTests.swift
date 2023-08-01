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
    
    let fileCountLimit = 5
    let fileSizeLimitInBytes = 1024
    
    var systemUnderTest: LogActor!
    var directory: URL!
    var rotations: [URL]!
    var subscription: Combine.Cancellable! { willSet { subscription?.cancel()} }
    
    override func setUp() async throws {
        rotations = []
        
        directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        systemUnderTest = try LogActor(directory: directory,
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
    
    /// Given: a Log Entry
    /// When: LogActor records the entry
    /// Then: the log entry is written to file
    func testLogActorRecordsEntry() async throws {
        XCTAssertEqual(rotations, [])
        
        let entry = LogEntry(category: "LogActorTests", namespace: nil, level: .error, message: UUID().uuidString, created: .init(timeIntervalSince1970: 0))
        try await systemUnderTest.record(entry)
        try await systemUnderTest.synchronize()
        
        XCTAssertEqual(rotations, [])
        
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let fileURL = try XCTUnwrap(files.first)
        let contents = try XCTUnwrap(FileManager.default.contents(atPath: fileURL.path))
        let decoded = try LogEntryCodec().decode(data: contents)
        XCTAssertEqual(decoded, entry)
    }
    
    /// Given: a Log Entry that takes up too much space
    /// When: LogActor records the entry
    /// Then: the log file is rotated and entry is written to a new file
    func testLogActorTriggersFileRotationOnRecord() async throws {
        XCTAssertEqual(rotations, [])
        let size = try LogEntry.minimumSizeForLogEntry(level: .error)
        let numberOfEntries = (fileSizeLimitInBytes/size) + 1
        let entries = (0..<numberOfEntries).map { LogEntry(category: "", namespace: nil, level: .error, message: "\($0)", created: .init(timeIntervalSince1970: Double($0))) }
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
    
    /// Given: a Log file
    /// When: LogActor deletes the log
    /// Then: the log file is emptied
    func testLogActorDeletesEntry() async throws {
        let entry = LogEntry(category: "LogActorTests", namespace: nil, level: .error, message: UUID().uuidString, created: .init(timeIntervalSince1970: 0))
        try await systemUnderTest.record(entry)
        try await systemUnderTest.synchronize()
        
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let fileURL = try XCTUnwrap(files.first)
        var contents = try XCTUnwrap(FileManager.default.contents(atPath: fileURL.path))
        XCTAssertNotNil(contents)
        
        try await systemUnderTest.deleteLogs()
        contents = try XCTUnwrap(FileManager.default.contents(atPath: fileURL.path))
        XCTAssertTrue(contents.isEmpty)
    }
    
    
    /// Given: a LogActor
    /// When: get all logs is excuted
    /// Then: all logs are returned
    func testLogActorReturnsLogList() async throws {
        var logs = try await systemUnderTest.getLogs()
        XCTAssertEqual(logs.count, 1)
        let size = try LogEntry.minimumSizeForLogEntry(level: .error)
        let numberOfEntries = (fileSizeLimitInBytes/size) + 1
        let entries = (0..<numberOfEntries).map { LogEntry(category: "", namespace: nil, level: .error, message: "\($0)", created: .init(timeIntervalSince1970: Double($0))) }
        for entry in entries {
            try await systemUnderTest.record(entry)
        }
        try await systemUnderTest.synchronize()
        
        logs = try await systemUnderTest.getLogs()
        XCTAssertEqual(logs.count, 2)
    }
}
