//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ArgumentParser
import Foundation
import AWSCLIUtils

struct GenerateSmokeTestsPackageManifestCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "generate-smoke-tests-package-manifest",
        abstract: "Generates the Package.swift manifest for the aws-sdk-swift/SmokeTests package."
    )

    @Argument(help: "The path to the aws-sdk-swift repository")
    var repoPath: String

    func run() throws {
        let generateSmokeTestsPackageManifest = GenerateSmokeTestsPackageManifest(
            repoPath: repoPath
        )
        try generateSmokeTestsPackageManifest.run()
    }
}

struct GenerateSmokeTestsPackageManifest {
    /// The path to the package repository
    let repoPath: String

    func run() throws {
        try FileManager.default.changeWorkingDirectory(repoPath)
        // Generate package manifest for smoke tests and save it as aws-sdk-swift/SmokeTests/Package.swift
        let smokeTestsContents = try generateSmokeTestsPackageManifestContents()
        try savePackageManifest(smokeTestsContents)
    }

    // MARK: - Helpers

    func generateSmokeTestsPackageManifestContents() throws -> String {
        return [
            // SmokeTests package manifest uses same prefix as one for aws-sdk-swift.
            try PackageManifestBuilder.contentReader(filename: "Package.Prefix")(),
            try generateServiceNamesArray(),
            try PackageManifestBuilder.contentReader(filename: "SmokeTestsPackage.Base")()
        ].joined(separator: .newline)
    }

    func generateServiceNamesArray() throws -> String {
        let servicesWithSmokeTests = try FileManager.default.servicesWithSmokeTests()
        let formatedServiceList = servicesWithSmokeTests.map { "\t\"\($0)\"," }.joined(separator: .newline)
        return [
            "// All services that have smoke tests generated for them.",
            "let serviceNames: [String] = [",
            formatedServiceList,
            "]"
        ].joined(separator: .newline)
    }

    func savePackageManifest(_ contents: String) throws {
        let packageFilePath = "SmokeTests/Package.swift"
        log("Saving package manifest to \(packageFilePath)...")
        try contents.write(
            toFile: packageFilePath,
            atomically: true,
            encoding: .utf8
        )
        log("Successfully saved package manifest to \(packageFilePath)")
    }
}
