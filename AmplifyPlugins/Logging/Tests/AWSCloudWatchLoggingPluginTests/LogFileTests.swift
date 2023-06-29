//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class LogFileTests: XCTestCase {
    
    var systemUnderTest: LogFile!
    var fileURL: URL!
    var sizeLimitInBytes: UInt64!
    
    override func setUp() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw NSError()
        }
        
        sizeLimitInBytes = 1024
        fileURL = url
        systemUnderTest = try LogFile(forWritingTo: fileURL, sizeLimitInBytes: sizeLimitInBytes)
    }
    
    override func tearDown() async throws {
        systemUnderTest = nil
        
        try FileManager.default.removeItem(at: fileURL)
        fileURL = nil
        sizeLimitInBytes = nil
    }
    
    func testLogFileWriteToSpaceLimit() throws {
        let bytes = (0..<sizeLimitInBytes).map { _ in UInt8.random(in: 0..<255) }
        let data = Data(bytes)
        
        let availableBeforeWrite = systemUnderTest.hasSpace(for: data)
        XCTAssertTrue(availableBeforeWrite)
        
        try systemUnderTest.write(data: data)

        let availableAfter = systemUnderTest.hasSpace(for: data)
        XCTAssertFalse(availableAfter)
        
        try systemUnderTest.synchronize()
        
        let contents = FileManager.default.contents(atPath: fileURL.path)
        XCTAssertEqual(contents, data)
    }
    
    func testLogFileWriteBeyondSpaceLimitThrowsError() throws {
        let bytes = (0..<sizeLimitInBytes).map { _ in UInt8.random(in: 0..<255) }
        let data = Data(bytes)
        
        let availableBeforeWrite = systemUnderTest.hasSpace(for: data)
        XCTAssertTrue(availableBeforeWrite)
        
        try systemUnderTest.write(data: data)

        let availableAfter = systemUnderTest.hasSpace(for: data)
        XCTAssertFalse(availableAfter)
        
        try systemUnderTest.synchronize()
        
        let contents = FileManager.default.contents(atPath: fileURL.path)
        XCTAssertEqual(contents, data)
        
        do {
            try systemUnderTest.write(data: data)
            XCTFail("Expecting failure")
        } catch {
            XCTAssertNotNil(error)
        }
        
        // Not partial writes allowed
        let contentsAfterFailure = FileManager.default.contents(atPath: fileURL.path)
        XCTAssertEqual(contentsAfterFailure, data)
    }
    
}
