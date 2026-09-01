//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum MockFileManagerError: Error {
    case removeItemError
}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockFileManager: FileManager, @unchecked Sendable {

    var removeItem: ((URL) -> Void)?

    var hasError: Bool = false
    var fileExists: Bool = false

    override init() {}

    override func removeItem(at URL: URL) throws {
        if hasError {
            throw MockFileManagerError.removeItemError
        }
        if let removeItem {
            removeItem(URL)
        }
    }

    override func fileExists(atPath path: String) -> Bool {
        return fileExists
    }
}
