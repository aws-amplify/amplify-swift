//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCLIUtils

/// `PackageDependencies` is a representation of contents of the .plist stored at packageDependencies.plist
struct PackageDependencies: Codable {
    static let fileName: String = "packageDependencies.plist"
    
    // Versions will always be defined in packageDependencies.plist
    // Versions are the only reference used when releasing.
    var awsCRTSwiftVersion: Version
    var clientRuntimeVersion: Version
    // Branches are normally set to main in packageDependencies.plist,
    // but may be changed during development on a feature branch if desired.
    // These values override environment vars set on CI.
    // Branches are ignored when building a release.
    var awsCRTSwiftBranch: String?
    var clientRuntimeBranch: String?
    // Paths may be used to point to paths on a development machine.
    // They may be set by the developer during testing, but should
    // never be set outside a development branch.
    // On CI, paths may be read from env vars and set at build time.
    // Paths are ignored when building a release.
    var awsCRTSwiftPath: String?
    var clientRuntimePath: String?
}

extension PackageDependencies {
    /// Returns `PackageDependencies` loaded from the file at the provided path.
    ///
    /// - Parameter path: The path to the `packageDependencies.plist` file. Defaults to `packageDependencies.plist`
    /// - Returns: `PackageDependencies` loaded from the file at the provided path.
    static func load(from path: String = fileName) throws -> PackageDependencies {
        let fileContents = try FileManager.default.loadContents(atPath: path)
        return try PropertyListDecoder().decode(PackageDependencies.self, from: fileContents)
    }
    
    /// Saves the package depdencies to the file at the provided path.
    /// If no file exists, then this will create a new file otherwise it will overwrite the existing file.
    ///
    /// - Parameter path: The path to the `packageDependencies.plist` file. Defaults to `packageDependencies.plist`
    func save(to path: String = fileName) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(self)
        try data.write(to: URL(fileURLWithPath: path))
    }
}
