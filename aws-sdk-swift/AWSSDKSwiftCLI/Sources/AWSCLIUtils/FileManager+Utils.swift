//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension FileManager {
    /// Changes the working directory to the provided path
    func changeWorkingDirectory(_ path: String) throws {
        log("Changing working directory to: \(path)")
        guard FileManager.default.changeCurrentDirectoryPath(path) else {
            throw Error("Failed to change directory to \(path)")
        }
        log("Changed working directory to: \(FileManager.default.currentDirectoryPath)")
    }
    
    /// Returns the contents of a file located at the provied path.
    func loadContents(atPath path: String) throws -> Data {
        guard let fileContents = FileManager.default.contents(atPath: path) else {
            throw Error("Failed to load data for file at path \(path)")
        }
        return fileContents
    }
    
    /// Returns the list of enabled services.
    /// A service is considered enabled if it was generated successfully and therefore a folder for the service and its contents, exists within `Sources/Services`
    ///
    /// - Returns: The list of enabled services.
    func enabledServices() throws -> [String] {
        try FileManager.default
            .contentsOfDirectory(atPath: "Sources/Services")
            .sorted()
            .filter { !$0.hasPrefix(".") }
    }

    /// Returns the list of Smithy runtime modules within `../smithy-swift/Sources/Core`
    ///
    /// - Returns: The list of Smithy runtime modules.
    func getSmithyRuntimeModules() throws -> [String] {
        try FileManager.default
            .contentsOfDirectory(atPath: "../smithy-swift/Sources")
            .sorted()
            .filter { $0 != "libxml2" } // Ignore libxml module
            .filter { !$0.hasPrefix(".") }
    }

    /// Returns the list of AWS runtime modules within `Sources/Core`
    ///
    /// - Returns: The list of AWS runtime modules.
    func getAWSRuntimeModules() throws -> [String] {
        try FileManager.default
            .contentsOfDirectory(atPath: "Sources/Core")
            .sorted()
            .filter { $0 != "AWSSDKForSwift" } // Ignore documentation module
            .filter { !$0.hasPrefix(".") }
    }

    /// Returns the list of integration tests.
    ///
    /// - Returns: The list of integration tests.
    func integrationTests() throws -> [String] {
        try FileManager.default
            .contentsOfDirectory(atPath: "IntegrationTests/Services")
            .sorted()
            .filter { !$0.hasPrefix(".") }
    }
}
