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
    private var originalWorkingDirectory: String!
    
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
    }
    
    override func tearDown() {
        try! FileManager.default.changeWorkingDirectory(originalWorkingDirectory)
        try! FileManager.default.removeItem(atPath: tmpPath)
        ProcessRunner.testRunner = nil
        super.tearDown()
    }
}
