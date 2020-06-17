//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum MockFileManagerError: Error {
    case failToDeleteDatabase
}
class MockFileManager: FileManager {

    var removeItem: ((URL) -> Void)?
    var hasError: Bool = false

    override init() {}

    override func removeItem(at URL: URL) throws {
        if hasError {
            throw MockFileManagerError.failToDeleteDatabase
        }
        if let removeItem = removeItem {
            removeItem(URL)
        }
    }
}
