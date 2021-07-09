//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PathKit
import XcodeProj

// MARK: Helpers
extension XcodeProj {
    func mainProject() -> PBXProject? {
        pbxproj.projects.first
    }

    func getOrCreateGroup(named group: String, in rootGroup: PBXGroup?) throws -> PBXGroup? {
        guard let rootGroup = rootGroup else {
            return nil
        }
        if let existingGroup = rootGroup.group(named: group) {
            return existingGroup
        }

        return try rootGroup.addGroup(named: group, options: GroupAddingOptions.withoutFolder).first
    }

    func add(file: Path, to group: PBXGroup, withRoot sourceRoot: Path) throws -> PBXBuildFile {
        let fileRef = try group.addFile(at: file, sourceRoot: sourceRoot)
        let buildFile = PBXBuildFile(file: fileRef)
        pbxproj.add(object: fileRef)
        pbxproj.add(object: buildFile)

        return buildFile
    }
}

// MARK: Add files to project
extension XcodeProj {
    func targets(named targetName: String,
                 ofType productType: PBXProductType) -> [PBXTarget] {
        pbxproj.targets(named: targetName).filter { $0.productType == productType }
    }

    func addResourceFile(_ file: PBXBuildFile, toTarget target: PBXTarget) throws {
        if let files = try target.resourcesBuildPhase()?.files, files.contains(file) {
            return
        }
        try target.resourcesBuildPhase()?.files?.append(file)
    }

    func addSourceFile(_ file: PBXBuildFile, toTarget target: PBXTarget) throws {
        if let files = try target.sourcesBuildPhase()?.files, files.contains(file) {
            return
        }
        try target.sourcesBuildPhase()?.files?.append(file)
    }
}
