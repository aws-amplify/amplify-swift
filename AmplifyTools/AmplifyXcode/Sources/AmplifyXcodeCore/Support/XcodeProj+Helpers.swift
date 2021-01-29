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

// MARK: addBuildFileTo
extension XcodeProj {
    func addBuildFileToResources(_ file: PBXBuildFile) {
        // TODO: should we find the proper build phase?
        pbxproj.resourcesBuildPhases.first?.files?.append(file)
    }

    func addBuildFileToSources(_ file: PBXBuildFile) {
        // TODO: should we find the proper build phase?
        pbxproj.sourcesBuildPhases.first?.files?.append(file)
    }
}
