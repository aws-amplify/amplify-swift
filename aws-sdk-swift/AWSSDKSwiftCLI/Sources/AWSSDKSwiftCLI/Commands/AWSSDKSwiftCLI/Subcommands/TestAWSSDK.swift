//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Algorithms
import ArgumentParser
import Foundation
import AWSCLIUtils

// MARK: - Command

struct TestAWSSDKCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "test-aws-sdk",
        abstract: "Builds the package and executes its tests",
        discussion: "swift test"
    )
    
    @Argument(help: "The path to the aws-sdk-swift repository")
    var repoPath: String
    
    @Option(help: "The number of test batches")
    var batches: UInt = 1
    
    func run() throws {
        let testAWSSDK = TestAWSSDK.standard(repoPath: repoPath, batches: batches)
        try testAWSSDK.run()
    }
}

// MARK: - TestAWSSDK

struct TestAWSSDK {
    /// The path to the aws-sdk-swift repository
    let repoPath: String
    
    /// The number of test batches
    /// The actual number of batches may be smaller depending on the number of services.
    /// For example, if the total number of services is 8, and the number of batches is 5, then the actual number of test batches will be 4
    let batches: UInt
    
    typealias PackageManifestGenerator = (
        _ packageFileName: String,
        _ services: [String]
    ) throws -> Void
    /// Generates a package manifest using the proivide file name and list of services
    let generatePackageManifest: PackageManifestGenerator
    
    private let packageFileName = "Package.swift"
    private let copiedPackageFileName = "Package.copy.swift"
    
    func run() throws {
        try FileManager.default.changeWorkingDirectory(repoPath)
        
        // If batches is 1, then run `swift test` with the current Package.swift
        guard batches > 1 else {
            log("Testing Package.swift...")
            let task = Process.swift.test()
            try _run(task)
            return
        }

        // Create batches of services
        let serviceBatches = try createBatches(Int(batches))
        
        // Create package manifests for each batch
        let packageManifests = try createPackageManifests(serviceBatches)
        
        // Test each package manifest
        try testAllPackages(packageManifests)
    }
    
    // MARK: - Helpers
    
    /// Returns batches of services
    /// Attempts to create `batches` number of batches, but the actual number of batches may be smaller. For example, if the total number of services is 8, and the provided number of batches is 5, this will return 4 batches.
    func createBatches(_ batches: Int) throws -> ChunksOfCountCollection<[String]> {
        log("Attempting to create \(batches) batches...")
        let services = try FileManager.default.enabledServices()
        let chunkSize: Int = {
            guard services.count >= batches else {
                log("Number of batches (\(batches)) provided is greater than the number of services (\(services.count)). Using \(services.count) instead.")
                return 1
            }
            return Int(ceil(Double(services.count) / Double(batches)))
        }()
        let serviceBatches = services.chunks(ofCount: chunkSize)
        log("Created \(serviceBatches.count) batches...")
        return serviceBatches
    }
    
    /// Creates package manifests for each batch in the provided list.
    /// Returns a list of the package manifests file names
    func createPackageManifests(_ serviceBatches: ChunksOfCountCollection<[String]>) throws -> [String] {
        var packageManifests: [String] = []
        
        for (index, serviceList) in serviceBatches.enumerated() {
            // Create the package manifest for each batch
            let packageManifest = "Package.TestBatch\(index + 1).swift"
            let services = Array(serviceList)
            try generatePackageManifest(packageManifest, services)
            packageManifests.append(packageManifest)
            log("""
            Created batch \(index + 1)
                * Manifest: \(packageManifest)
                * Size: \(services.count)
                * First Service: \(services.first!)
                * Last Service: \(services.last!)
            """)
        }
        
        return packageManifests
    }
    
    /// Runs tests for each package manifest in the provided list
    func testAllPackages(_ packageManifests: [String]) throws {
        // Move the current Package.swift to a new file to be restored later
        try renamePackageManifest()
        
        // Run 'swift test' for each package manifest
        try packageManifests.forEach(testPackage)
        
        // Restor the original package manifest
        try restorePackageManifest()
    }
    
    /// Runs tests using the provided package manifest
    ///
    /// This renames the provided package to `Package.swift` and then runs `swift test`
    /// When finished, it renames `Package.swift` back to the provided package file name.
    ///
    func testPackage(_ package: String) throws {
        log("Testing \(package)...")
        // Set this package as the Package.swift
        try FileManager.default.moveItem(
            atPath: package,
            toPath: packageFileName
        )
        let task = Process.swift.test()
        try _run(task)
    
        // Move the file back when we are finished
        try FileManager.default.moveItem(
            atPath: packageFileName,
            toPath: package
        )
    }
    
    /// Moves the original `Package.swift` to `Package.copy.swift`
    func renamePackageManifest() throws {
        try FileManager.default.moveItem(
            atPath: packageFileName,
            toPath: copiedPackageFileName
        )
    }
    
    /// Restores the original package manifest to `Package.swift`
    func restorePackageManifest() throws {
        try FileManager.default.moveItem(
            atPath: copiedPackageFileName,
            toPath: packageFileName
        )
    }
}

// MARK: - Factory

extension TestAWSSDK {
    /// Returns the standard aws sdk tester
    ///
    /// - Parameters:
    ///   - repoPath: The path to the aws-sdk-swift respository
    ///   - batches: The number of test batches
    ///
    /// - Returns: The standard aws sdk tester
    static func standard(
        repoPath: String,
        batches: UInt
    ) -> Self {
        TestAWSSDK(
            repoPath: repoPath,
            batches: batches
        ) { packageFileName, services in
            let command = GeneratePackageManifest.standard(
                repoPath: ".",
                packageFileName: packageFileName,
                services: services
            )
            try command.run()
        }
    }
}
