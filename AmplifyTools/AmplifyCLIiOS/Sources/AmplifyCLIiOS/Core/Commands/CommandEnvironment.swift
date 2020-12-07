//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct CommandEnvironment: Decodable, AmplifyCommandEnvironment {
    internal let basePathURL: URL
    let basePath: String
    let currentFolder: String

    init(basePath: String) {
        self.basePath = basePath
        self.basePathURL = URL(fileURLWithPath: basePath)
        self.currentFolder = basePathURL.lastPathComponent
    }
}

// MARK: - AmplifyCommandEnvironmentFileManager
extension CommandEnvironment {
   // TODO: resolve home path ~ https://developer.apple.com/documentation/foundation/filemanager/1642853-homedirectory
    func path(for file: String ) -> String {
        return URL(fileURLWithPath: file, relativeTo: basePathURL).path
    }

    func path(for components: [String]) -> String {
        return path(for: components.joined(separator: "/"))
    }

    @discardableResult func create(directory: String) throws -> String {
        let url = URL(fileURLWithPath: directory, relativeTo: basePathURL)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url.path
        } catch {
            throw AmplifyCommandError(.unknown, error: error)
        }
    }

    func create(file: String, content: String) {
        FileManager.default.createFile(atPath: path(for: file), contents: content.data(using: .utf8))
    }

    func content(of directory: String) throws -> [String] {
        guard FileManager.default.directoryExists(atPath: directory) else {
            throw AmplifyCommandError(.folderNotFound, error: nil, recoverySuggestion: "Folder \(directory) not found")
        }
        do {
            let content = try FileManager.default.contentsOfDirectory(atPath: directory)
            return content
        } catch {
            throw AmplifyCommandError(.unknown, error: error)
        }
    }

    func directoryExists(at path: String) -> Bool {
        FileManager.default.directoryExists(atPath: path)
    }
}

// MARK: - AmplifyCommandEnvironmentXcode
extension CommandEnvironment {
    private func loadXcode(project path: String) throws -> XcodeProject {
        let xcodeProjFiles = try content(of: path).filter {
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
            let xcodeProject = try loadXcode(project: path)
            try xcodeProject.add(files: files, toGroup: group)
            try xcodeProject.update()
        } catch {
            throw AmplifyCommandError(.xcodeProject, error: error)
        }
    }
}
