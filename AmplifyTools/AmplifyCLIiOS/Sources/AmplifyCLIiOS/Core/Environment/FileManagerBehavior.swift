//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyFileManagerBehavior {
    func resolveHomeDirectoryIn(path: String) -> String
    func createDirectory(at: URL, withIntermediateDirectories: Bool)
    func createFile(atPath: String, contents: Data)
    func directoryExists(atPath: String) -> Bool
    func contentsOfDirectory(atPath: String) -> [String]
}
