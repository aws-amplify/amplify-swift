//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AmplifyXcodeCore

class MockAmplifyCommandEnvironment: Mock, AmplifyCommandEnvironment {
    var basePathURL: URL
    var basePath: String
    var fileManager: AmplifyFileManager

    required init(basePath: String, fileManager: AmplifyFileManager) {
        // TODO: how can we re-use initializer?
        // maybe a factory method instead of a public initializer?
        self.basePath = fileManager.resolveHomeDirectoryIn(path: basePath)
        self.basePathURL = URL(fileURLWithPath: self.basePath)
        self.fileManager = fileManager
    }

    func path(for filePath: String) -> String {
        captureCall("path")
        return filePath
    }

    func path(for components: [String]) -> String {
        captureCall("pathForComponents")
        return ""
    }

    func glob(pattern: String) -> [String] {
        captureCall("glob")
        return []
    }

    func createDirectory(atPath path: String) throws -> String {
        captureCall("createDirectory")
        return path
    }

    func createFile(atPath filePath: String, content: String) throws -> String {
        captureCall("createFile")
        return filePath
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        captureCall("contentsOfDirectory")
        return []
    }

    func directoryExists(atPath dirPath: String) -> Bool {
        captureCall("directoryExists")
        return true
    }

    func fileExists(atPath dirPath: String) -> Bool {
        captureCall("fileExists")
        return true
    }

    func createXcodeFile(withPath path: String, ofType type: XcodeProjectFileType) -> XcodeProjectFile {
        captureCall("createXcodeFile")
        return XcodeProjectFile(path, type: type)
    }

    func addFilesToXcodeProject(projectPath path: String,
                                files: [XcodeProjectFile],
                                toGroup group: String,
                                inTarget: XcodeProjectTarget) throws {
        captureCall("addFilesToXcodeProject")
    }
}
