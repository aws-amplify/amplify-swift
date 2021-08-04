//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Collection of environment functions consumed by commands' tasks
public protocol AmplifyCommandEnvironmentFileManager {
    var basePathURL: URL { get }
    var basePath: String { get }
    var fileManager: AmplifyFileManager { get }

    init(basePath: String, fileManager: AmplifyFileManager)

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

    /// Returns true if file at `atPath` relative to `basePath` exists
    func fileExists(atPath filePath: String) -> Bool
}

/// Collection of Xcode utilities
public protocol AmplifyCommandEnvironmentXcode {
    /// Given a file path, returns an XcodeProjectFile reference
    func createXcodeFile(withPath path: String, ofType type: XcodeProjectFileType) -> XcodeProjectFile

    /// Reads an Xcode project file at `projectPath`, retrieves or creates a group `group` if it doesn't exist
    /// and adds `files` to it
    func addFilesToXcodeProject(projectPath: String,
                                files: [XcodeProjectFile],
                                toGroup group: String,
                                inTarget target: XcodeProjectTarget) throws
}

public typealias AmplifyCommandEnvironment = AmplifyCommandEnvironmentFileManager & AmplifyCommandEnvironmentXcode
