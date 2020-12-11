//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PathKit

extension FileManager: AmplifyFileManager {
    func createDirectory(at path: URL, withIntermediateDirectories: Bool) throws {
        try createDirectory(at: path, withIntermediateDirectories: withIntermediateDirectories, attributes: nil)
    }

    func createFile(atPath: String, contents: Data?) -> Bool {
        createFile(atPath: atPath, contents: contents, attributes: nil)
    }

    func glob(pattern: String) -> [String] {
        Path.glob(pattern).map { $0.string }
    }
}
