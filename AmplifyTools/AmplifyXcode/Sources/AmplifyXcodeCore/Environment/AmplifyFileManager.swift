//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Subset of Foundation FileManager APIs.
/// It's sole purpose is to favor testability of AmplifyCommandEnvironment conforming structs/classes
public protocol AmplifyFileManager {
    func resolveHomeDirectoryIn(path: String) -> String
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func createFile(atPath: String, contents: Data?) -> Bool
    func directoryExists(atPath: String) -> Bool
    func fileExists(atPath filePath: String) -> Bool
    func contentsOfDirectory(atPath: String) throws -> [String]
    func glob(pattern: String) -> [String]
}
