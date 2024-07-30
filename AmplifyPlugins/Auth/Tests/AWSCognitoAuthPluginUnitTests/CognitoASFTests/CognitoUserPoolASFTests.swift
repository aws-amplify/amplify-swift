//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import XCTest

class CognitoUserPoolASFTests: XCTestCase {
    private var userPool: CognitoUserPoolASF!
   
    override func setUp() {
        userPool = CognitoUserPoolASF()
    }
    
    override func tearDown() {
        userPool = nil
    }
       
    /// Given: A CognitoUserPoolASF
    /// When: userContextData is invoked
    /// Then: A non-empty string is returned
    func testUserContextData_shouldReturnData() async throws {
        let deviceInfo = await ASFDeviceInfo(id: "mockedDevice")
        let result = try userPool.userContextData(
            for: "TestUser",
            deviceInfo: deviceInfo,
            appInfo: ASFAppInfo(),
            configuration: .testData
        )
        XCTAssertFalse(result.isEmpty)
    }
    
    /// Given: A CognitoUserPoolASF
    /// When: calculateSecretHash is invoked
    /// Then: A non-empty string is returned
    func testCalculateSecretHash_shouldReturnHash() throws {
        let result = try userPool.calculateSecretHash(
            contextJson: "contextJson",
            clientId: "clientId"
        )
        XCTAssertFalse(result.isEmpty)
    }
    
    /// Given: A CognitoUserPoolASF
    /// When: calculateSecretHash is invoked with a clientId that cannot be parsed
    /// Then: A ASFError.hashKey is thrown
    func testCalculateSecretHash_withInvalidClientId_shouldThrowHashKeyError() {
        do {
            let result = try userPool.calculateSecretHash(
                contextJson: "contextJson",
                clientId: "🕺🏼" // This string cannot be represented using .ascii, so it will throw an error
            )
            XCTFail("Expected ASFError.hashKey, got \(result)")
        } catch let error as ASFError {
            XCTAssertEqual(error, .hashKey)
        } catch {
            XCTFail("Expected ASFError.hashKey, for \(error)")
        }
    }
}
