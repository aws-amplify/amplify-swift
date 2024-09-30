//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import Algorithms
import XCTest
import AWSCLIUtils

class TestAWSSDKTests: CLITestCase {
    
    // MARK: - Helpers
    
    func createServiceFolders(_ services: [String]) {
        services.forEach {
            try! FileManager.default.createDirectory(
                atPath: "Sources/Services/\($0)",
                withIntermediateDirectories: true
            )
        }
    }
    
    func createGoldenPathEnvironment() throws {
        let services = ["A", "B", "C", "D", "E", "F", "G", "H"]
        
        // Create services
        createServiceFolders(services)
        
        // Create packageDependencies.plist
        let deps = try PackageDependencies(
            awsCRTSwiftVersion: .init("1.2.3"),
            clientRuntimeVersion: .init("3.2.1")
        )
        try! deps.save()
        
        // Create Package.swift
        let contents = "// package manifest"
        try! contents.write(
            toFile: "Package.swift",
            atomically: true, encoding: .utf8
        )
    }
    
    // MARK: - Tests
    
    // MARK: Golden Path
    
    func testGoldenPath() throws {
        try createGoldenPathEnvironment()

        var commands: [String] = []
        let runner = ProcessRunner {
            commands.append($0.commandString)
        }
        ProcessRunner.testRunner = runner
        
        var packages: [String] = []
        
        let subject = TestAWSSDK.mock(batches: 4) { packageFileName, services in
            packages.append("\(packageFileName) \(services.joined(separator: "-"))")
            try! "\(packageFileName)".write(
                toFile: packageFileName,
                atomically: true, encoding: .utf8
            )
        }
        try! subject.run()
        
        XCTAssertEqual(commands.count, 4)
        XCTAssertTrue(commands.allSatisfy { $0.hasSuffix("swift test") })
        XCTAssertEqual(packages, [
            "Package.TestBatch1.swift A-B",
            "Package.TestBatch2.swift C-D",
            "Package.TestBatch3.swift E-F",
            "Package.TestBatch4.swift G-H",
        ])
    }
    
    func testRunWhenBatchesIsOne() {
        let services = ["A", "B", "C", "D", "E", "F", "G", "H"]
        createServiceFolders(services)
        var commands: [String] = []
        let runner = ProcessRunner {
            commands.append($0.commandString)
        }
        ProcessRunner.testRunner = runner
        let subject = TestAWSSDK.mock(batches: 1)
        try! subject.run()
        
        XCTAssertEqual(commands.count, 1)
        XCTAssertTrue(commands[0].hasSuffix("swift test"))
    }
    
    // MARK: createBatches()
    
    func testCreateBatches() {
        let services = ["A", "B", "C", "D", "E", "F", "G", "H"]
        createServiceFolders(services)
        let subject = TestAWSSDK.mock()
        
        let result1 = try! subject.createBatches(1)
        XCTAssertServiceBatchEquals(result1, [["A", "B", "C", "D", "E", "F", "G", "H"]])
        
        let result2 = try! subject.createBatches(2)
        XCTAssertServiceBatchEquals(result2, [["A", "B", "C", "D"], ["E", "F", "G", "H"]])
        
        let result3 = try! subject.createBatches(3)
        XCTAssertServiceBatchEquals(result3, [["A", "B", "C"], ["D", "E", "F"], ["G", "H"]])
        
        let result4 = try! subject.createBatches(4)
        XCTAssertServiceBatchEquals(result4, [["A", "B"], ["C", "D"], ["E", "F"], ["G", "H"]])
        
        let result5 = try! subject.createBatches(5)
        XCTAssertServiceBatchEquals(result5, [["A", "B"], ["C", "D"], ["E", "F"], ["G", "H"]])
        
        let result6 = try! subject.createBatches(6)
        XCTAssertServiceBatchEquals(result6, [["A", "B"], ["C", "D"], ["E", "F"], ["G", "H"]])
        
        let result7 = try! subject.createBatches(7)
        XCTAssertServiceBatchEquals(result7, [["A", "B"], ["C", "D"], ["E", "F"], ["G", "H"]])
        
        let result8 = try! subject.createBatches(8)
        XCTAssertServiceBatchEquals(result8, [["A"], ["B"], ["C"], ["D"], ["E"], ["F"], ["G"], ["H"]])
        
        let result9 = try! subject.createBatches(100)
        XCTAssertServiceBatchEquals(result9, [["A"], ["B"], ["C"], ["D"], ["E"], ["F"], ["G"], ["H"]])
    }
    
    // MARK: testPackage()
    
    func testPackage() {
        let packageName = "Package.TestBatch1.swift"
        let contents = "// package manifest"
        try! contents.write(
            toFile: packageName,
            atomically: true, encoding: .utf8
        )
        var command: String!
        var testBatchContents: String!
        let runner = ProcessRunner {
            command = $0.commandString
            testBatchContents = try! String(
                contentsOfFile: "Package.swift",
                encoding: .utf8
            )
        }
        ProcessRunner.testRunner = runner
        
        let subject = TestAWSSDK.mock()
        try! subject.testPackage(packageName)
        
        let packageContents = try? String(
            contentsOfFile: "Package.swift",
            encoding: .utf8
        )
        
        XCTAssertTrue(command.hasSuffix("swift test"))
        XCTAssertEqual(testBatchContents, contents)
        XCTAssertNil(packageContents)
    }
    
    // MARK: renamePackageManifest()
    
    func testRenamePackageManifest() {
        let contents = "// package manifest"
        try! contents.write(
            toFile: "Package.swift",
            atomically: true, encoding: .utf8
        )
        let subject = TestAWSSDK.mock()
        try! subject.renamePackageManifest()
        let newPackage = try! String(
            contentsOfFile: "Package.copy.swift",
            encoding: .utf8
        )
        let oldPackage = try? String(
            contentsOfFile: "Package.swift",
            encoding: .utf8
        )
        XCTAssertEqual(newPackage, contents)
        XCTAssertNil(oldPackage)
    }
    
    // MARK: - restorePackageManifest()
    
    func testRestorePackageManifest() {
        let contents = "// package manifest"
        try! contents.write(
            toFile: "Package.copy.swift",
            atomically: true, encoding: .utf8
        )
        let subject = TestAWSSDK.mock()
        try! subject.restorePackageManifest()
        let copy = try? String(
            contentsOfFile: "Package.copy.swift",
            encoding: .utf8
        )
        let original = try! String(
            contentsOfFile: "Package.swift",
            encoding: .utf8
        )
        XCTAssertEqual(original, contents)
        XCTAssertNil(copy)
    }
}

// MARK: - Mocks

extension TestAWSSDK {
    static func mock(
        repoPath: String = ".",
        batches: UInt = 1,
        generatePackageManifest: @escaping PackageManifestGenerator = { _,_ in }
    ) -> Self {
        TestAWSSDK(
            repoPath: repoPath,
            batches: batches,
            generatePackageManifest: generatePackageManifest
        )
    }
}

// MARK: - XCTAssert

func XCTAssertServiceBatchEquals(
    _ batches: @autoclosure () throws -> ChunksOfCountCollection<[String]>,
    _ expected: @autoclosure () throws -> [[String]],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let _batches = try! batches()
    let _expected = try! expected()
    for (i, batch) in _batches.enumerated() {
        XCTAssertEqual(Array(batch), _expected[i])
    }
}
