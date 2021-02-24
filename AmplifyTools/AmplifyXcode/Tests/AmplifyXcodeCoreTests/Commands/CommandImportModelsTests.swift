//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyXcodeCore

class CommandImportModelsTests: XCTestCase {
    let basePath = "/Test/Env/Project"
    var fileManager = MockAmplifyFileManager()
    var environment: MockAmplifyCommandEnvironment?
    var executor: CommandExecutable?

    static let modelsFilesCount = 3

    struct TestCommandImportModels: CommandExecutable {
        var environment: AmplifyCommandEnvironment
        init(environment: AmplifyCommandEnvironment) {
            self.environment = environment
        }
    }

    class MockedCommandEnvironment: MockAmplifyCommandEnvironment {
        override func glob(pattern: String) -> [String] {
            _ = super.glob(pattern: pattern)
            return Array.init(repeating: "File.swift", count: modelsFilesCount)
        }
    }

    override func setUp() {
        environment = MockedCommandEnvironment(basePath: basePath, fileManager: MockAmplifyFileManager())
        executor = TestCommandImportModels(environment: environment!)
    }

    func testImportModelsSuccessfulFlow() {
        let result = executor?.exec(command: CommandImportModels())
        XCTAssertEqual(environment?.directoryExistsCalledTimes, 1)
        XCTAssertEqual(environment?.globCalledTimes, 1)
        XCTAssertEqual(environment?.createXcodeFileCalledTimes, CommandImportModelsTests.modelsFilesCount)
        XCTAssertEqual(environment?.addFilesToXcodeProjectCalledTimes, 1)
        if case let .failure(error) = result {
            XCTFail("CommandImportModels failed with \(error)")
        }
    }

}
