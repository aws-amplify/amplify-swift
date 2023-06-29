////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class RotatingLogBatchTests: XCTestCase {
    var fileURL: URL!
    
    override func setUp() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw NSError()
        }
        
        fileURL = url
        let logFile = try LogFile(forWritingTo: fileURL, sizeLimitInBytes: 1024)
        let entry = LogEntry(category: "Auth", namespace: "namespace", level: .error, message: "error message")
        let data = try LogEntryCodec().encode(entry: entry)
        try logFile.write(data: data)
    }
    
    override func tearDown() async throws {
        do {
            try FileManager.default.removeItem(at: fileURL)
            fileURL = nil
        } catch {
            
        }
    }
    
    func testSuccessfullyyReadEntriesFromDisk() {
        let rotatingLogBatch = RotatingLogBatch(url: fileURL)
        let entries = try? rotatingLogBatch.readEntries()
        XCTAssertEqual(entries?.count, 1)
        XCTAssertEqual(entries![0].category, "Auth")
        XCTAssertEqual(entries![0].logLevel.rawValue, 0)
        XCTAssertEqual(entries![0].message, "error message")
        XCTAssertEqual(entries![0].namespace, "namespace")
    }
    
    func testSuccessfullyCompleteEntriesAndRemovesFile() throws {
        let rotatingLogBatch = RotatingLogBatch(url: fileURL)
        try rotatingLogBatch.complete()
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.absoluteString))
    }
}

extension RotatingLogBatch: CustomStringConvertible {
    public var description: String {
        return "\((url.path as NSString).lastPathComponent)"
    }
}
