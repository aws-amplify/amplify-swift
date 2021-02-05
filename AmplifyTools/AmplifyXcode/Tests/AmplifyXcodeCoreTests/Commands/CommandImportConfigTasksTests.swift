//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyXcodeCore

class CommandImportConfigTasksTests: XCTestCase {
    let basePath = "/Test/Env/Project"
    let taskArgs = CommandImportConfig.CommandImportConfigArgs()
    var fileManager = MockAmplifyFileManager()
    var environment: MockAmplifyCommandEnvironment?

    override func setUp() {
        fileManager = MockAmplifyFileManager()
        environment = MockAmplifyCommandEnvironment(basePath: basePath, fileManager: fileManager)
    }

    func testAmplifyFolderExistTaskSuccess() {
        let result = ImportConfigTasks.amplifyFolderExist(environment: environment!, args: taskArgs)
        if case let .failure(error) = result {
            XCTFail("Task failed with error: \(error)")
        }
        XCTAssertEqual(environment?.directoryExistsCalledTimes, 1)
    }

    func testAmplifyFolderExistTaskFailure() {
        class FailingEnvironment: MockAmplifyCommandEnvironment {
            override func directoryExists(atPath dirPath: String) -> Bool {
                _ = super.directoryExists(atPath: dirPath)
                return false
            }
        }
        let environment = FailingEnvironment(basePath: basePath, fileManager: fileManager)
        let result = ImportConfigTasks.amplifyFolderExist(environment: environment, args: taskArgs)
        if case .success = result {
            XCTFail()
        }
        XCTAssertEqual(environment.directoryExistsCalledTimes, 1)
    }

    func testAmplifyConfigFilesExistTaskSuccess() {
        let result = ImportConfigTasks.configFilesExist(environment: environment!, args: taskArgs)
        if case let .failure(error) = result {
            XCTFail("Task failed with error: \(error)")
        }
        XCTAssertEqual(environment?.fileExistsCalledTimes, 2)
    }

    func testAmplifyConfigFilesExistTaskFailure() {
        class FailingEnvironment: MockAmplifyCommandEnvironment {
            override func fileExists(atPath dirPath: String) -> Bool {
                _ = super.fileExists(atPath: dirPath)
                return false
            }
        }
        let environment = FailingEnvironment(basePath: basePath, fileManager: fileManager)
        let result = ImportConfigTasks.configFilesExist(environment: environment, args: taskArgs)
        if case .success = result {
            XCTFail()
        }
        XCTAssertEqual(environment.fileExistsCalledTimes, 1)
    }

    func testAddConfigFilesToXcodeTask() {
        let result = ImportConfigTasks.addConfigFilesToXcodeProject(environment: environment!, args: taskArgs)
        if case let .failure(error) = result {
            XCTFail("Task failed with error: \(error)")
        }
        XCTAssertEqual(environment?.pathCalledTimes, 2)
        XCTAssertEqual(environment?.createXcodeFileCalledTimes, 2)
        XCTAssertEqual(environment?.addFilesToXcodeProjectCalledTimes, 1)
    }
}
