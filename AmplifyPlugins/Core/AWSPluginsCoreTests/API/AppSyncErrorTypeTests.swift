//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPluginsCore

class AppSyncErrorTypeTests: XCTestCase {
    func testAppSyncErrorTypeFromErrorString() {
        let errorTypes: [String: AppSyncErrorType] = [
            AppSyncErrorType.conflictUnhandled.rawValue: .conflictUnhandled,
            AppSyncErrorType.conditionalCheck.rawValue: .conditionalCheck,
            AppSyncErrorType.unauthorized.rawValue: .unauthorized,
            AppSyncErrorType.operationDisabled.rawValue: .operationDisabled,
            "unknownError": .unknown("unknownError")
        ]
        for error in errorTypes {
            XCTAssertEqual(error.value, AppSyncErrorType(error.key))
        }
    }
}
