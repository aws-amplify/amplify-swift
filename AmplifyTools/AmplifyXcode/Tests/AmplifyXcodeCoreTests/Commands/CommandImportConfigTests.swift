//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyXcodeCore

class CommandImportConfigTests: XCTestCase {
    let basePath = "/Test/Env/Project"
    var fileManager = MockAmplifyFileManager()
    var environment: MockAmplifyCommandEnvironment?
    var executor: CommandExecutable?

    struct TestCommandImportConfig: CommandExecutable {
        var environment: AmplifyCommandEnvironment
        init(environment: AmplifyCommandEnvironment) {
            self.environment = environment
        }
    }

    override func setUp() {
        environment = MockAmplifyCommandEnvironment(basePath: basePath, fileManager: MockAmplifyFileManager())
        executor = TestCommandImportConfig(environment: environment!)
    }

    func testImportConfigSuccessfulFlow() {
        let result = executor?.exec(command: CommandImportConfig())
        XCTAssertEqual(environment?.directoryExistsCalledTimes, 1)
        XCTAssertEqual(environment?.createXcodeFileCalledTimes, 2)
        XCTAssertEqual(environment?.addFilesToXcodeProjectCalledTimes, 1)
        if case .failure = result {
            XCTFail()
        }
    }
}
