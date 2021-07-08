//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// AmplifyCommandEnvironment default implementation
public struct CommandEnvironment: AmplifyCommandEnvironment {
    public let basePathURL: URL
    public let basePath: String
    public let fileManager: AmplifyFileManager

    public init(basePath: String, fileManager: AmplifyFileManager) {
        self.basePath = fileManager.resolveHomeDirectoryIn(path: basePath)
        self.basePathURL = URL(fileURLWithPath: self.basePath, isDirectory: true)
        self.fileManager = fileManager
    }
}

// MARK: - AmplifyCommandEnvironmentFileManager
extension CommandEnvironment {
    public func path(for subpath: String) -> String {
        return URL(fileURLWithPath: subpath, relativeTo: basePathURL).path
    }

    public func path(for components: [String]) -> String {
        return path(for: components.joined(separator: "/"))
    }

    public func glob(pattern: String) -> [String] {
        let fullPath = path(for: pattern)
        return fileManager.glob(pattern: fullPath).map { $0 }
    }

    @discardableResult public func createDirectory(atPath path: String) throws -> String {
        let url = URL(fileURLWithPath: path, relativeTo: basePathURL)
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            return url.path
        } catch {
            throw AmplifyCommandError(.unknown, error: error)
        }
    }

    @discardableResult public func createFile(atPath filePath: String, content: String) throws -> String {
        let fullPath = path(for: filePath)
        if fileManager.createFile(atPath: fullPath, contents: content.data(using: .utf8)) {
            return fullPath
        }
        throw AmplifyCommandError(.unknown, error: nil)
    }

    public func contentsOfDirectory(atPath directoryPath: String) throws -> [String] {
        let fullPath = path(for: directoryPath)
        guard fileManager.directoryExists(atPath: fullPath) else {
            throw AmplifyCommandError(
                .folderNotFound,
                errorDescription: "Folder \(fullPath) not found",
                recoverySuggestion: nil,
                error: nil)
        }
        do {
            let content = try fileManager.contentsOfDirectory(atPath: fullPath)
            return content
        } catch {
            throw AmplifyCommandError(.unknown, error: error)
        }
    }

    public func directoryExists(atPath dirPath: String) -> Bool {
        fileManager.directoryExists(atPath: path(for: dirPath))
    }

    public func fileExists(atPath filePath: String) -> Bool {
        fileManager.fileExists(atPath: path(for: filePath))
    }
}

// MARK: - AmplifyCommandEnvironmentXcode
extension CommandEnvironment {
    private func loadFirstXcodeProject(fromDirectory path: String) throws -> XcodeProject {
        let xcodeProjFiles = try contentsOfDirectory(atPath: path).filter {
            $0.hasSuffix("xcodeproj")
        }

        if xcodeProjFiles.count != 1 {
            throw AmplifyCommandError(
                .xcodeProject,
                error: XcodeProjectError.notFound(path: path))
        }
        let projectName = xcodeProjFiles[0]

        return try XcodeProject(at: path, projPath: self.path(for: projectName))
    }

    public func createXcodeFile(withPath path: String, ofType type: XcodeProjectFileType) -> XcodeProjectFile {
        return XcodeProjectFile(path, type: type)
    }

    public func addFilesToXcodeProject(
        projectPath path: String,
        files: [XcodeProjectFile],
        toGroup group: String,
        inTarget target: XcodeProjectTarget) throws {
        do {
            let xcodeProject = try loadFirstXcodeProject(fromDirectory: path)
            try xcodeProject.add(files: files, toGroup: group, inTarget: target)
            try xcodeProject.synchronize()
        } catch {
            if case let XcodeProjectError.targetNotFound(name: targetName) = error {
                throw AmplifyCommandError(.xcodeProject,
                                          errorDescription: "Target \(targetName) not found",
                                          recoverySuggestion: "Manually add Amplify files to your Xcode project.")
            }
            throw AmplifyCommandError(.xcodeProject, error: error)
        }
    }
}
