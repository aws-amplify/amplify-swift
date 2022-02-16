//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct UploadFile {
    let fileURL: URL
    let temporaryFileCreated: Bool
    let size: UInt64

    init(fileURL: URL, temporaryFileCreated: Bool, size: UInt64) {
        self.fileURL = fileURL
        self.temporaryFileCreated = temporaryFileCreated
        self.size = size
    }
}
