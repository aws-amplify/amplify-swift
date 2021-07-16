//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PathKit
import XcodeProj

/// Xcode project error
public enum XcodeProjectError: Error {
    case notFound(path: String)
    case noPbxProjFound
    case groupNotFound(group: String)
    case addFileFailed
    case targetNotFound(name: String)
}

/// Xcode project target
public enum XcodeProjectTarget {
    /// primary target (name matches project file)
    case primary
    case named(String)
}

/// Xcode project file type
public enum XcodeProjectFileType {
    /// resource file
    case resource

    /// source file (i.e. Swift, Obj-C)
    case source
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

    private func resolveTarget(_ target: XcodeProjectTarget) throws -> PBXTarget {
        let targetName: String
        switch target {
        case .primary:
            targetName = project.mainProject()?.name ?? "primary"
        case .named(let name):
            targetName = name
        }

        if let targetRef = project.targets(named: targetName, ofType: .application).first {
            return targetRef
        }

        throw XcodeProjectError.targetNotFound(name: targetName)
    }
}

// MARK: Add files
extension XcodeProject {
    func add(files: [XcodeProjectFile],
             toGroup group: String,
             inTarget target: XcodeProjectTarget) throws {
        guard let mainProject = project.mainProject() else {
            throw XcodeProjectError.noPbxProjFound
        }

        let sourceRoot = Path(basePath)

        guard let targetGroup = try project.getOrCreateGroup(named: group, in: mainProject.mainGroup) else {
            throw XcodeProjectError.groupNotFound(group: group)
        }

        let targetRef = try resolveTarget(target)

        for file in files {
            let path = Path(file.path)

            guard let buildFile = try? project.add(file: path, to: targetGroup, withRoot: sourceRoot) else {
                throw XcodeProjectError.addFileFailed
            }

            switch file.type {
            case .resource:
                try project.addResourceFile(buildFile, toTarget: targetRef)
            case .source:
                try project.addSourceFile(buildFile, toTarget: targetRef)
            }
        }
    }
}
