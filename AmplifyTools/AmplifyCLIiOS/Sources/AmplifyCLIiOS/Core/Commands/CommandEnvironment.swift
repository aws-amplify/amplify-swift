//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PathKit

/// AmplifyCommandEnvironment default implementation
struct CommandEnvironment: Decodable, AmplifyCommandEnvironment {
    internal let basePathURL: URL
    let basePath: String
    let currentFolder: String

    init(basePath: String) {
        self.basePath = FileManager.default.resolveHomeDirectoryIn(path: basePath)
        self.basePathURL = URL(fileURLWithPath: self.basePath)
        self.currentFolder = basePathURL.lastPathComponent
    }
}

// MARK: - AmplifyCommandEnvironmentFileManager
extension CommandEnvironment {
    func path(for file: String ) -> String {
        return URL(fileURLWithPath: file, relativeTo: basePathURL).path
    }

    func path(for components: [String]) -> String {
        return path(for: components.joined(separator: "/"))
    }

    func glob(pattern: String) -> [String] {
        let fullPath = path(for: pattern)
        return Path.glob(fullPath).map { $0.string }
    }

    @discardableResult func createDirectory(atPath path: String) throws -> String {
        let url = URL(fileURLWithPath: path, relativeTo: basePathURL)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url.path
        } catch {
            throw AmplifyCommandError(.unknown, error: error)
        }
    }

    @discardableResult func createFile(atPath filePath: String, content: String) throws -> String {
        let fullPath = path(for: filePath)
        if FileManager.default.createFile(atPath: fullPath, contents: content.data(using: .utf8)) {
            return fullPath
        }
        throw AmplifyCommandError(.unknown, error: nil)
    }

    func contentsOfDirectory(atPath directoryPath: String) throws -> [String] {
        let fullPath = path(for: directoryPath)
        guard FileManager.default.directoryExists(atPath: fullPath) else {
            throw AmplifyCommandError(.folderNotFound, error: nil, recoverySuggestion: "Folder \(fullPath) not found")
        }
        do {
            let content = try FileManager.default.contentsOfDirectory(atPath: fullPath)
            return content
        } catch {
            throw AmplifyCommandError(.unknown, error: error)
        }
    }

    func directoryExists(atPath dirPath: String) -> Bool {
        FileManager.default.directoryExists(atPath: path(for: dirPath))
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

    func xcode(project path: String, add files: [XcodeProjectFile], toGroup group: String) throws {
        do {
            let xcodeProject = try loadFirstXcodeProject(fromDirectory: path)
            try xcodeProject.add(files: files, toGroup: group)
            try xcodeProject.synchronize()
        } catch {
            throw AmplifyCommandError(.xcodeProject, error: error)
        }
    }
}
