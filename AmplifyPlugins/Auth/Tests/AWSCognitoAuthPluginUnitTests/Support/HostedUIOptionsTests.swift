//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
import XCTest

class HostedUIOptionsTests: XCTestCase {
    
    // MARK: - Decoding
    
    /// - Given: A valid json payload with non-nil values depicting a `HostedUIOptions`
    /// - When: The payload is decoded
    /// - Then: The payload is decoded successfully
    func testHostedUIOptionsDecodeWithNonNullValuesSuccess() {
        let jsonString =
        """
        {
            "scopes": [
                "phone",
                "email",
                "openid",
                "profile"
            ],
            "providerInfo": {
                "idpIdentifier": "dummyIdentifier"
            },
            "preferPrivateSession": true
        }
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data else {
                XCTFail("Input JSON is invalid")
                return
            }
            let hostedUIOptions = try JSONDecoder().decode(
                HostedUIOptions.self, from: data
            )

            XCTAssertEqual(hostedUIOptions.scopes.count, 4)
            XCTAssertTrue(hostedUIOptions.scopes.contains("phone"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("email"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("openid"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("profile"))
            XCTAssertEqual(hostedUIOptions.preferPrivateSession, true)
            XCTAssertNil(hostedUIOptions.presentationAnchor)
            XCTAssertNil(hostedUIOptions.providerInfo.authProvider)
            XCTAssertEqual(hostedUIOptions.providerInfo.idpIdentifier, "dummyIdentifier")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }
    
    /// - Given: A valid json payload with null values for optional fields depicting a `HostedUIOptions`
    /// - When: The payload is decoded
    /// - Then: The payload is decoded successfully
    func testHostedUIOptionsDecodeWithNullValuesSuccess() {
        let jsonString =
        """
        {
            "scopes": [
                "phone",
                "email",
                "openid",
                "profile"
            ],
            "providerInfo": {
                "idpIdentifier": "dummyIdentifier"
            },
            "preferPrivateSession": true,
            "nonce": null,
            "lang": null,
            "login_hint": null,
            "prompt": null,
            "resource": null
        }
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data else {
                XCTFail("Input JSON is invalid")
                return
            }
            let hostedUIOptions = try JSONDecoder().decode(
                HostedUIOptions.self, from: data
            )

            XCTAssertEqual(hostedUIOptions.scopes.count, 4)
            XCTAssertTrue(hostedUIOptions.scopes.contains("phone"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("email"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("openid"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("profile"))
            XCTAssertEqual(hostedUIOptions.preferPrivateSession, true)
            XCTAssertNil(hostedUIOptions.presentationAnchor)
            XCTAssertNil(hostedUIOptions.providerInfo.authProvider)
            XCTAssertEqual(hostedUIOptions.providerInfo.idpIdentifier, "dummyIdentifier")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }
    
    /// - Given: A valid json payload with valid values for optional fields depicting a `HostedUIOptions`
    /// - When: The payload is decoded
    /// - Then: The payload is decoded successfully
    func testHostedUIOptionsDecodeWithOptionalValuesSuccess() {
        let jsonString =
        """
        {
            "scopes": [
                "phone",
                "email",
                "openid",
                "profile"
            ],
            "providerInfo": {
                "idpIdentifier": "dummyIdentifier"
            },
            "preferPrivateSession": true,
            "nonce": "dummyNonce",
            "lang": "en",
            "login_hint": "username",
            "prompt": "login consent",
            "resource": "myapp://"
        }
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data else {
                XCTFail("Input JSON is invalid")
                return
            }
            let hostedUIOptions = try JSONDecoder().decode(
                HostedUIOptions.self, from: data
            )

            XCTAssertEqual(hostedUIOptions.scopes.count, 4)
            XCTAssertTrue(hostedUIOptions.scopes.contains("phone"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("email"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("openid"))
            XCTAssertTrue(hostedUIOptions.scopes.contains("profile"))
            XCTAssertEqual(hostedUIOptions.preferPrivateSession, true)
            XCTAssertNil(hostedUIOptions.presentationAnchor)
            XCTAssertNil(hostedUIOptions.providerInfo.authProvider)
            XCTAssertEqual(hostedUIOptions.providerInfo.idpIdentifier, "dummyIdentifier")
            XCTAssertEqual(hostedUIOptions.nonce, "dummyNonce")
            XCTAssertEqual(hostedUIOptions.language, "en")
            XCTAssertEqual(hostedUIOptions.loginHint, "username")
            XCTAssertEqual(hostedUIOptions.prompt, "login consent")
            XCTAssertEqual(hostedUIOptions.resource, "myapp://")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }
    
    /// - Given: A valid json payload with null value for scopes field depicting a `HostedUIOptions`
    /// - When: The payload is decoded
    /// - Then: The operation should throw an error
    func testHostedUIOptionsDecodeWithNullScopesFailure() {
        let jsonString =
        """
        {
            "scopes": null,
            "providerInfo": {
                "idpIdentifier": "dummyIdentifier"
            },
            "preferPrivateSession": true
        }
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data else {
                XCTFail("Input JSON is invalid")
                return
            }
            
            _ = try JSONDecoder().decode(
                HostedUIOptions.self, from: data
            )
            
            XCTFail("Decoding should not succeed")
        } catch {
            XCTAssertNotNil(error)
            guard case DecodingError.valueNotFound = error else {
                XCTFail("Error should be of type valueNotFound")
                return
            }
        }
    }
    
    /// - Given: A valid json payload with invalid value type for scopes field depicting a `HostedUIOptions`
    /// - When: The payload is decoded
    /// - Then: The operation should throw an error
    func testHostedUIOptionsDecodeWithInvalidScopesFailure() {
        let jsonString =
        """
        {
            "scopes": "email",
            "providerInfo": {
                "idpIdentifier": "dummyIdentifier"
            },
            "preferPrivateSession": true
        }
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data else {
                XCTFail("Input JSON is invalid")
                return
            }
            
            _ = try JSONDecoder().decode(
                HostedUIOptions.self, from: data
            )
            
            XCTFail("Decoding should not succeed")
        } catch {
            XCTAssertNotNil(error)
            guard case DecodingError.typeMismatch = error else {
                XCTFail("Error should be of type typeMismatch")
                return
            }
        }
    }
    
    /// - Given: A valid json payload with missing key for scopes field depicting a `HostedUIOptions`
    /// - When: The payload is decoded
    /// - Then: The operation should throw an error
    func testHostedUIOptionsDecodeWithMissingScopesFailure() {
        let jsonString =
        """
        {
            "providerInfo": {
                "idpIdentifier": "dummyIdentifier"
            },
            "preferPrivateSession": true
        }
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data else {
                XCTFail("Input JSON is invalid")
                return
            }
            
            _ = try JSONDecoder().decode(
                HostedUIOptions.self, from: data
            )
            
            XCTFail("Decoding should not succeed")
        } catch {
            XCTAssertNotNil(error)
            guard case DecodingError.keyNotFound = error else {
                XCTFail("Error should be of type typeMismatch")
                return
            }
        }
    }
}
