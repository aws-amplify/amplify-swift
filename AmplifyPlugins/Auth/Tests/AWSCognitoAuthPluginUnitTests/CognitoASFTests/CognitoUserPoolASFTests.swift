//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import XCTest

class CognitoUserPoolASFTests: XCTestCase {
    private var pool: CognitoUserPoolASF!
   
    override func setUp() {
        pool = CognitoUserPoolASF()
    }
    
    override func tearDown() {
        pool = nil
    }
    
    func testUserContextData_shouldReturnData() throws {
        let result = try pool.userContextData(
            for: "TestUser",
            deviceInfo: ASFDeviceInfo(id: "mockedDevice"),
            appInfo: ASFAppInfo(),
            configuration: .testData
        )
        XCTAssertFalse(result.isEmpty)
    }
    
    func testcalculateSecretHash_withInvalidClientId_shouldThrowHashKeyError() {
        do {
            let result = try pool.calculateSecretHash(
                contextJson: "contextJson",
                clientId: "🕺🏼"
            )
            XCTFail("Expected ASFError.hashKey, got \(result)")
        } catch let error as ASFError {
            XCTAssertEqual(error, .hashKey)
        } catch {
            XCTFail("Expected ASFError.hashKey, for \(error)")
        }
    }
}
