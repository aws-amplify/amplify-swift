//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PathKit
import XcodeProj

public enum XcodeProjectError: Error {
    case notFound(path: String)
    case noPbxProjFound
    case groupNotFound(group: String)
    case addFileFailed
}

public enum XcodeProjectFileType {
    case resource, source
}

public struct XcodeProjectFile: Equatable {
    let path: String
    let type: XcodeProjectFileType

    init(_ path: String, type: XcodeProjectFileType) {
        self.path = path
        self.type = type
    }
}

/// Wrapper around `XcodeProj` library, provides convenience utilities functions to
/// access and update an Xcode project.
struct XcodeProject {
    let project: XcodeProj
    let basePath: String
    let projFilePath: String
    let pbxProjFilePath: String

    init(at path: String, projPath: String) throws {
        self.basePath = path
        self.project = try XcodeProj(pathString: projPath)
        self.projFilePath = projPath
        self.pbxProjFilePath = URL(fileURLWithPath: projPath).appendingPathComponent("project.pbxproj").path
    }

    func synchronize() throws {
        try project.pbxproj.write(path: Path(pbxProjFilePath), override: true)
    }
}

// MARK: Add files
extension XcodeProject {
    func add(files: [XcodeProjectFile], toGroup group: String) throws {
        guard let mainProject = project.mainProject() else {
            throw XcodeProjectError.noPbxProjFound
        }

        let sourceRoot = Path(basePath)

        // TODO: unwrap and check targetGroup before proceeding
        guard let targetGroup = try project.getOrCreateGroup(named: group, in: mainProject.mainGroup) else {
            throw XcodeProjectError.groupNotFound(group: group)
        }

        for file in files {
            let path = Path(file.path)

            guard let buildFile = try? project.add(file: path, to: targetGroup, withRoot: sourceRoot) else {
                throw XcodeProjectError.addFileFailed
            }

            switch file.type {
            case .resource:
                project.addBuildFileToResources(buildFile)
            case .source:
                project.addBuildFileToSources(buildFile)
            }
        }
    }
}
