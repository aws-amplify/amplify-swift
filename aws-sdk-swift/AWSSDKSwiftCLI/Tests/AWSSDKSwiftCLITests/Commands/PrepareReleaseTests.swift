//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import XCTest
import AWSCLIUtils

class PrepareReleaseTests: CLITestCase {
    
    // MARK: - Helpers
    
    func createPackageVersion(_ version: Version) {
        try! "\(version)".write(
            toFile: "Package.version" ,
            atomically: true,
            encoding: .utf8
        )
    }

    func createNextPackageVersion(_ version: Version) {
        try! "\(version)".write(
            toFile: "Package.version.next" ,
            atomically: true,
            encoding: .utf8
        )
    }

    // MARK: - Tests
    
    // MARK: Golden Path
    
    func testGoldenPath() throws {
        var commands: [String] = []
        let runner = ProcessRunner {
            commands.append($0.commandString)
        }
        ProcessRunner.testRunner = runner
        let previousVersion = try Version("1.2.3")
        let newVersion = try Version("1.2.4")
        let futureVersion = try Version("1.2.5")
        createPackageVersion(previousVersion)
        createNextPackageVersion(newVersion)

        let buildRequest = """
        {
            "features": []
        }
        """
        FileManager.default.createFile(atPath: "../build-request.json", contents: Data(buildRequest.utf8))

        let mapping = "{}"
        FileManager.default.createFile(atPath: "../feature-service-id.json", contents: Data(mapping.utf8))

        let subject = PrepareRelease.mock(repoType: .awsSdkSwift, diffChecker: { _,_ in true })
        try! subject.run()
        
        let versionFromFile = try! Version.fromFile("Package.version")
        XCTAssertEqual(versionFromFile, newVersion)

        let futureVersionFromFile = try! Version.fromFile("Package.version.next")
        XCTAssertEqual(futureVersionFromFile, futureVersion)

        let releaseManifest = try! ReleaseManifest.fromFile("release-manifest.json")
        XCTAssertEqual(releaseManifest.name, "\(newVersion)")
        XCTAssertEqual(releaseManifest.tagName, "\(newVersion)")
        
        XCTAssertEqual(commands.count, 5)
        XCTAssertTrue(commands[0].contains("git add"))
        XCTAssertTrue(commands[1].contains("git commit"))
        XCTAssertTrue(commands[2].contains("git tag"))
        XCTAssertTrue(commands[3].contains("git log"))
        XCTAssertTrue(commands[4].contains("git status"))
    }
    
    func testRunBailsEarlyIfThereAreNoChanges() throws {
        var commands: [String] = []
        let runner = ProcessRunner {
            commands.append($0.commandString)
        }
        ProcessRunner.testRunner = runner
        let previousVersion = try Version("1.2.3")
        let newVersion = try Version("1.2.4")
        createPackageVersion(previousVersion)
        createNextPackageVersion(newVersion)

        let subject = PrepareRelease.mock(diffChecker: { _,_ in false })
        try! subject.run()
        
        let versionFromFile = try! Version.fromFile("Package.version")
        XCTAssertEqual(versionFromFile, previousVersion)
        
        XCTAssertTrue(commands.isEmpty)
    }
    
    // MARK: createNewVersion()
    
    func testCreateNewSDKVersion() async throws {
        let previousVersion = try Version("1.2.3")
        let newVersion = try Version("1.3.0")
        let futureVersion = try Version("1.3.1")
        createPackageVersion(previousVersion)
        createNextPackageVersion(newVersion)
        let subject = PrepareRelease.mock(repoType: .awsSdkSwift)
        let result = try subject.createNewVersion(previousVersion)
        XCTAssertEqual(result, newVersion)

        let versionFromFile = try! Version.fromFile("Package.version")
        XCTAssertEqual(versionFromFile, newVersion)

        let nextVersionFromFile = try! Version.fromFile("Package.version.next")
        XCTAssertEqual(nextVersionFromFile, futureVersion)
    }

    func testCreateNewSmithySwiftVersion() throws {
        let previousVersion = try Version("1.2.3")
        let newVersion = try Version("1.3.0")
        let futureVersion = try Version("1.4.0")
        createPackageVersion(previousVersion)
        createNextPackageVersion(newVersion)
        let subject = PrepareRelease.mock(repoType: .smithySwift)
        let result = try! subject.createNewVersion(previousVersion)
        XCTAssertEqual(result, newVersion)

        let versionFromFile = try! Version.fromFile("Package.version")
        XCTAssertEqual(versionFromFile, newVersion)

        let nextVersionFromFile = try! Version.fromFile("Package.version.next")
        XCTAssertEqual(nextVersionFromFile, futureVersion)
    }

    // MARK: getPreviousVersion()

    func testGetPreviousVersionFromPackageVersion() throws {
        let version = try Version("1.2.3")
        createPackageVersion(version)
        let subject = PrepareRelease.mock()
        let result = try! subject.getPreviousVersion()
        XCTAssertEqual(result, version)
    }

    // MARK: getNextVersion()

    func testGetNewVersionFromPackageVersionDotNext() throws {
        let version = try Version("1.2.3")
        createNextPackageVersion(version)
        let subject = PrepareRelease.mock()
        let result = try! subject.getNewVersion()
        XCTAssertEqual(result, version)
    }

    // MARK: stageFiles()
    
    func testStageFilesForAWSSDKSwift() {
        var command: String!
        let runner = ProcessRunner {
            command = $0.commandString
        }
        ProcessRunner.testRunner = runner
        let subject = PrepareRelease.mock(repoType: .awsSdkSwift)
        try! subject.stageFiles()
        XCTAssertTrue(command.hasSuffix("git add Package.swift Package.version Package.version.next packageDependencies.plist Sources/Services Sources/Core/AWSSDKForSwift/Documentation.docc/AWSSDKForSwift.md"))
    }
    
    func testStageFilesForSmithySwift() {
        var command: String!
        let runner = ProcessRunner {
            command = $0.commandString
        }
        ProcessRunner.testRunner = runner
        let subject = PrepareRelease.mock(repoType: .smithySwift)
        try! subject.stageFiles()
        XCTAssertTrue(command.hasSuffix("git add Package.version Package.version.next"))
    }
}

// MARK: - Mocks

extension PrepareRelease {
    static func mock(
        repoType: PrepareRelease.Repo = .awsSdkSwift,
        repoPath: String = ".",
        sourceCodeArtifactId: String = "source-code-artifact-id",
        diffChecker: @escaping DiffChecker = { _,_ in true }
    ) -> Self {
        PrepareRelease(
            repoType: repoType,
            repoOrg: .awslabs,
            repoPath: repoPath,
            sourceCodeArtifactId: sourceCodeArtifactId,
            diffChecker: diffChecker
        )
    }
}
