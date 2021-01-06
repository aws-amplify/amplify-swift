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

class MockFileManager: FileManager {

    var removeItem: ((URL) -> Void)?

    var hasError: Bool = false
    var fileExists: Bool = false

    override init() {}

    override func removeItem(at URL: URL) throws {
        if hasError {
            throw MockFileManagerError.removeItemError
        }
        if let removeItem = removeItem {
            removeItem(URL)
        }
    }

    override func fileExists(atPath path: String) -> Bool {
        return fileExists
    }
}
