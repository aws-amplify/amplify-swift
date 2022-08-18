//
//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import Foundation

class MockFileManager: FileManagerBehaviour {
    private let tempDirectory = FileManager.default.temporaryDirectory
    private let fileName: String

    init(fileName: String) {
        self.fileName = fileName
    }

    deinit {
        try? FileManager.default.removeItem(at: tempDirectory.appendingPathComponent(fileName))
    }

    var removeItemCount = 0
    func removeItem(atPath path: String) throws {
        removeItemCount += 1
    }

    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return [tempDirectory]
    }

    var fileExists = false
    func fileExists(atPath path: String) -> Bool {
        return fileExists
    }

    var mockedFileSize = 0
    var fileSizeCount = 0
    func fileSize(for url: URL) -> Byte {
        fileSizeCount += 1
        return mockedFileSize
    }

    var createDirectoryCount = 0
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool) throws {
        createDirectoryCount += 1
    }
}
