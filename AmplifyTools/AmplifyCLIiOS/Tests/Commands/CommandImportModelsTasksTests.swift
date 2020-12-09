//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

class CommandImportModelsTasksTests: XCTestCase {
    let basePath = "/Test/Env/Project"
    let taskArgs = CommandImportModels.CommandImportModelsArgs()
    var fileManager = MockAmplifyFileManager()
    var environment: MockAmplifyCommandEnvironment?

    override func setUp() {
        fileManager = MockAmplifyFileManager()
        environment = MockAmplifyCommandEnvironment(basePath: basePath, fileManager: fileManager)
    }

    func testProjectHasGeneratedModelsSuccess() {
        let result = CommandImportModelsTasks.projectHasGeneratedModels(environment: environment!, args: taskArgs)
        if case .failure = result {
            XCTFail()
        }
        XCTAssertEqual(environment?.pathCalledTimes, 1)
        XCTAssertEqual(environment?.directoryExistsCalledTimes, 1)
    }

    func testaddGeneratedModelsToProjectaddsFilesToXcodeProject() {
        class CustomEnvironment: MockAmplifyCommandEnvironment {
            override func glob(pattern: String) -> [String] {
                [
                   "Todo.swift",
                   "Note.swift",
               ]

            }
        }
        let environment = CustomEnvironment(basePath: basePath, fileManager: fileManager)
        if case .failure = CommandImportModelsTasks.projectHasGeneratedModels(environment: environment, args: taskArgs) {
            XCTFail()
        }

        if case .failure = CommandImportModelsTasks.addGeneratedModelsToProject(environment: environment, args: taskArgs) {
            XCTFail()
        }
        XCTAssertEqual(environment.createXcodeFileCalledTimes, 2) // one call for each model file found
        XCTAssertEqual(environment.addFilesToXcodeProjectCalledTimes, 1)

    }

    func testProjectHasGeneratedModelsThrowsIfNotAmplifyProject() {
        class FailingEnvironment: MockAmplifyCommandEnvironment {
            override func directoryExists(atPath dirPath: String) -> Bool {
                _ = super.directoryExists(atPath: dirPath)
                return false
            }
        }
        let environment = FailingEnvironment(basePath: basePath, fileManager: fileManager)
        let result = CommandImportModelsTasks.projectHasGeneratedModels(environment: environment, args: taskArgs)
        if case .success = result {
            XCTFail()
        }
    }

}
