//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Collection of environment functions consumed by commands' tasks
protocol AmplifyCommandEnvironmentFileManager {
    var basePathURL: URL { get }
    var basePath: String { get }
    var currentFolder: String { get }

    init(basePath: String)

    /// Given a file name, returns its full path relative to `basePath`
    func path(for file: String ) -> String

    /// Given an array of file names, returns their full path relative to `basePath`
    func path(for components: [String]) -> String

    func glob(pattern: String) -> [String]

    /// Creates a directory at path `path` relative to `basePath`
    func createDirectory(atPath path: String) throws -> String

    /// Creates a file at specified `file` path  relative to `basePath`.
    /// Returns the full path of the newly create file.
    func createFile(atPath filePath: String, content: String) throws -> String

    /// Reads content of given directory path relative to `basePath`
    func contentsOfDirectory(atPath path: String) throws -> [String]

    /// Returns true if directory at `atPath` relative to `basePath` exists
    func directoryExists(atPath dirPath: String) -> Bool
}

/// Collection of Xcode utilities
protocol AmplifyCommandEnvironmentXcode {

    /// reads an Xcode project file at `project path`, read or create a group `group` if it doesn't exist
    /// and adds `files` to it
    func xcode(project path: String, add files: [XcodeProjectFile], toGroup group: String) throws
}

typealias AmplifyCommandEnvironment = AmplifyCommandEnvironmentFileManager & AmplifyCommandEnvironmentXcode
