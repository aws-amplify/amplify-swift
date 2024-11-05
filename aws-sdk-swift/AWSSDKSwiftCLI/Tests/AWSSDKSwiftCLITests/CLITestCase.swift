//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import XCTest
import AWSCLIUtils

class CLITestCase: XCTestCase {
    let tmpPath = "tmp"
    let projectPath = "aws-sdk-swift-or-smithy-swift"
    private var originalWorkingDirectory: String!
    
    /// Creates a temp directory that contains a project dir.
    ///
    /// The project dir is set as CWD when setup is complete.
    /// This folder structure permits Trebuchet artifacts to be written in the parent of the project directory.
    /// At the conclusion of the test, the tear-down method deletes the entire temp directory.
    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(atPath: tmpPath)
        ProcessRunner.testRunner = nil
        try! FileManager.default.createDirectory(
            atPath: tmpPath,
            withIntermediateDirectories: false
        )
        originalWorkingDirectory = FileManager.default.currentDirectoryPath
        try! FileManager.default.changeWorkingDirectory(tmpPath)
        try! FileManager.default.createDirectory(
            atPath: projectPath,
            withIntermediateDirectories: false
        )
        try! FileManager.default.changeWorkingDirectory(projectPath)
    }
    
    override func tearDown() {
        try! FileManager.default.changeWorkingDirectory(originalWorkingDirectory)
        try! FileManager.default.removeItem(atPath: tmpPath)
        ProcessRunner.testRunner = nil
        super.tearDown()
    }
}
