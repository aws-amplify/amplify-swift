//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyCognitoASF
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class CognitoUserPoolASFTests: XCTestCase, @unchecked Sendable {
    private var userPool: CognitoUserPoolASF!

    override func setUp() {
        userPool = CognitoUserPoolASF()
    }

    override func tearDown() {
        userPool = nil
    }

    /// Given: A CognitoUserPoolASF and a fixed device, so the test never reads `UIScreen`
    /// When: userContextData is invoked
    /// Then: A non-empty string is returned
    func testUserContextData_shouldReturnData() async throws {
        let deviceInfo = FixedASFDevice(id: "mockedDevice")
        let result = try await userPool.userContextData(
            for: "TestUser",
            deviceInfo: deviceInfo,
            appInfo: ASFAppInfo(),
            configuration: .testData
        )
        XCTAssertFalse(result.isEmpty)
    }
}
