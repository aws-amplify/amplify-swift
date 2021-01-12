//
// Copyright Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FileManager {
    func directoryExists(atPath path: String) -> Bool {
        var isDirectory = ObjCBool(false)
        let exists = fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func resolveHomeDirectoryIn(path: String) -> String {
        if let first = path.first, first == "~" {
            return path.replacingCharacters(in: ...path.startIndex,
                                            with: FileManager.default.homeDirectoryForCurrentUser.path)
        }
        return path
    }
}
