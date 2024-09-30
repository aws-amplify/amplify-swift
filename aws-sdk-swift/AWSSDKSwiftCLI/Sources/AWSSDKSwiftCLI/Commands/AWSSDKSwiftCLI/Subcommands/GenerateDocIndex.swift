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

struct GenerateDocIndexCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "generate-doc-index",
        abstract: "Generates the documentation index for the AWSSDKforSwift documentation target."
    )

    @Argument(help: "The path to the aws-sdk-swift repository")
    var repoPath: String

    func run() throws {
        try FileManager.default.changeWorkingDirectory(repoPath)
        let contents = try generateDocIndexContents()
        try saveDocIndex(contents)
    }

    // MARK: - Helpers

    /// Returns the contents of the generated doc index.
    /// This determines the versions of the dependencies and the list of services to include and then generates the doc index with those values.
    ///
    /// - Returns: The contents of the generated doc index.
    func generateDocIndexContents() throws -> String {
        let services = try resolveServices()
        let smithyRuntimeModules = try resolveSmithyRuntimeModules()
        let awsRuntimeModules = try resolveAWSRuntimeModules()
        log("Creating doc index contents...")
        let contents = try DocIndexBuilder(
            services: services,
            smithyRuntimeModules: smithyRuntimeModules,
            awsRuntimeModules: awsRuntimeModules
        ).build()
        log("Successfully created doc index contents")
        return contents
    }

    /// Saves the doc index file.
    /// If no file exists, then this will create a new file. Otherwise, this will overwrite the existing file.
    ///
    /// - Parameter contents: The contents of the doc index.
    func saveDocIndex(_ contents: String) throws {
        let docIndexFileName = "Sources/Core/AWSSDKForSwift/Documentation.docc/AWSSDKForSwift.md"
        log("Saving doc index to \(docIndexFileName)...")
        try contents.write(
            toFile: docIndexFileName,
            atomically: true,
            encoding: .utf8
        )
        log("Successfully saved doc index to \(docIndexFileName)")
    }

    /// Returns the list of services to include in the doc index.
    /// If an explicit list of services was provided by the command, then this returns the specified services.
    /// Otherwise, this returns the list of services that exist within `Sources/Services`
    ///
    /// - Returns: The list of services to include in the doc index
    func resolveServices() throws -> [String] {
        log("Resolving services...")
        let resolvedServices: [String]
        log("Using list of services that exist within Sources/Services")
        resolvedServices = try FileManager.default.enabledServices()
        log("Resolved list of services: \(resolvedServices.count)")
        return resolvedServices
    }

    /// Returns the list of Smithy runtime modules within `../smithy-swift/Sources/Core` to include in the doc index.
    ///
    /// - Returns: The list of Smithy runtime moduls to include in the doc index
    func resolveSmithyRuntimeModules() throws -> [String] {
        log("Resolving Smithy runtime modules...")
        let resolvedSmithyRuntimeModules: [String]
        log("Using list of Smithy runtime modules that exist within ../smithy-swift/Sources/Core")
        resolvedSmithyRuntimeModules = try FileManager.default.getSmithyRuntimeModules()
        log("Resolved list of Smithy runtime modules: \(resolvedSmithyRuntimeModules.count)")
        return resolvedSmithyRuntimeModules
    }

    /// Returns the list of AWS runtime modules within `Sources/Core` to include in the doc index.
    ///
    /// - Returns: The list of AWS runtime moduls to include in the doc index
    func resolveAWSRuntimeModules() throws -> [String] {
        log("Resolving AWS runtime modules...")
        let resolvedAWSRuntimeModules: [String]
        log("Using list of AWS runtime modules that exist within Sources/Core")
        resolvedAWSRuntimeModules = try FileManager.default.getAWSRuntimeModules()
        log("Resolved list of AWS runtime modules: \(resolvedAWSRuntimeModules.count)")
        return resolvedAWSRuntimeModules
    }
}
