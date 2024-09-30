//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ArgumentParser
import Foundation
import AWSCLIUtils

// MARK: - Command

struct SyncClientRuntimeVersionCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "sync-client-runtime-version",
        abstract: "Sets the version of ClientRuntime in aws-sdk-swift to the version defined in smithy-swift"
    )
    
    @Argument(help: "The path to the aws-sdk-swift repository")
    var repoPath: String
    
    @Option(help: "The path to the smithy-swift repository. If no value is provided, then it assumes the repo is located next to the aws-sdk-swift repo (../smith-swift)")
    var smithySwiftPath: String?
    
    func run() throws {
        let syncClientRuntimeVersion = SyncClientRuntimeVersion(
            repoPath: repoPath,
            smithySwiftPath: smithySwiftPath
        )
        try syncClientRuntimeVersion.run()
    }
}

// MARK: - SyncClientRuntimeVersion

/// Retrieves the version for ClientRuntime from the `smithy-swift` repository and stores the version in `packageDependencies.plist`
struct SyncClientRuntimeVersion {
    /// The path to the package repository
    let repoPath: String
    /// The path to the smithy-swift repository
    /// If `nil`, then this it defaults to a path next to the specified `repoPath`, aka `<repoPath>/../smithy-swift`
    let smithySwiftPath: String?
    
    /// Retrieves the version for ClientRuntime from the `smithy-swift` repository and stores the version in `packageDependencies.plist`
    func run() throws {
        try FileManager.default.changeWorkingDirectory(repoPath)
        try syncClientRuntimeVersion()
    }
    
    // MARK: - Helpers
    
    /// Returns the path to the `smithy-swift` repository.
    ///
    /// - Returns: The path to the `smithy-swift` repository
    func resolveSmithySwiftPath() -> String {
        smithySwiftPath ?? "../smithy-swift"
    }
    
    /// Returns the version of ClientRuntime retrieved from the `Package.version` file located in `smithy-swift`.
    ///
    /// - Returns: The version of ClientRuntime retrieved from the `Package.version` file located in `smithy-swift`.
    func smithySwiftPackageVersion() throws -> Version {
        let path = resolveSmithySwiftPath() + "/Package.version"
        log("Loading ClientRuntime version from \(path)")
        let version = try Version.fromFile(path)
        log("Successfully loaded ClientRuntime version \(version.description)")
        return version
    }
    
    /// Syncs the version of ClientRuntime by setting the version to the value defined in the `Package.version` file located in`smithy-swift'.
    func syncClientRuntimeVersion() throws {
        log("Syncing ClientRuntime version...")
        let version = try smithySwiftPackageVersion()
        try setClientRuntimeVersion(version)
    }
    
    /// Sets the ClientRuntime version in `packageDependencies.plist` to the provided value.
    ///
    /// - Parameter version: The version to set for ClientRuntime.
    func setClientRuntimeVersion(_ version: Version) throws {
        log("Setting ClientRuntime version to \(version.description)")
        var packageDependencies = try PackageDependencies.load()
        packageDependencies.clientRuntimeVersion = version
        try packageDependencies.save()
        log("Successfully saved ClientRuntime version to \(version.description)")
    }
}
