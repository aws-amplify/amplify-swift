//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCLIUtils

// Builds the release notes
struct ReleaseNotesBuilder {
    let previousVersion: Version
    let newVersion: Version
    let repoOrg: PrepareRelease.Org
    let repoType: PrepareRelease.Repo
    let commits: [String]
    
    // MARK: - Build
    
    func build() -> String {
        let contents = [
            "## What's Changed",
            buildCommits(),
            .newline,
            "**Full Changelog**: https://github.com/\(repoOrg.rawValue)/\(repoType.rawValue)/compare/\(previousVersion)...\(newVersion)"
        ]
        return contents.joined(separator: .newline)
    }
    
    // Adds a preceding `*` to each commit string
    // This renders the list of commits as a list in markdown
    func buildCommits() -> String {
        commits
            .map { "* \($0)"}
            .joined(separator: .newline)
    }
}
