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
       
    /// Given: A CognitoUserPoolASF
    /// When: userContextData is invoked
    /// Then: A non-empty string is returned
    func testUserContextData_shouldReturnData() throws {
        let result = try pool.userContextData(
            for: "TestUser",
            deviceInfo: ASFDeviceInfo(id: "mockedDevice"),
            appInfo: ASFAppInfo(),
            configuration: .testData
        )
        XCTAssertFalse(result.isEmpty)
    }
    
    /// Given: A CognitoUserPoolASF
    /// When: calculateSecretHash is invoked
    /// Then: A non-empty string is returned
    func testCalculateSecretHash_shouldReturnHash() throws {
        let result = try pool.calculateSecretHash(
            contextJson: "contextJson",
            clientId: "clientId"
        )
    }
    
    /// Given: A CognitoUserPoolASF
    /// When: calculateSecretHash is invoked with a clientId that cannot be parsed
    /// Then: A ASFError.hashKey is thrown
    func testCalculateSecretHash_withInvalidClientId_shouldThrowHashKeyError() {
        do {
            let result = try pool.calculateSecretHash(
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
