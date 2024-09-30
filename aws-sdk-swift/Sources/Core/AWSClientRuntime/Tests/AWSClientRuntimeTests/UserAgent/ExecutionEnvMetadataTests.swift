//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSClientRuntime
import XCTest

class ExecutionEnvMetadataTests: XCTestCase {
    func test_detectExecEnv_returnsNilWhenExecutionEnvIsUnset() {
        unsetenv("AWS_EXECUTION_ENV")
        XCTAssertNil(ExecutionEnvMetadata.detectExecEnv())
    }

    func test_detectExecEnv_returnsNilWhenExecutionEnvIsEmptyString() {
        setenv("AWS_EXECUTION_ENV", "", 1)
        XCTAssertNil(ExecutionEnvMetadata.detectExecEnv())
    }

    func test_detectExecEnv_returnsSanitizedDescription() throws {
        setenv("AWS_EXECUTION_ENV", "Elastic 🤡 Service", 1)
        let subject = try XCTUnwrap(ExecutionEnvMetadata.detectExecEnv())
        XCTAssertEqual(subject.description, "exec-env/Elastic---Service")
    }
}
