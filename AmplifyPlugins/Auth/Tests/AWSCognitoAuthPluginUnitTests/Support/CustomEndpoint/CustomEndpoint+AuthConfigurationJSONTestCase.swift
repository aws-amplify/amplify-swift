//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin
import Amplify
import XCTest

class CustomEndpoint_AuthConfigurationJSONTestCase: XCTestCase {
    /// Given: The `awsCognitoAuthPlugin` portion of an `amplifyconfiguration.json`
    /// When: The `Endpoint` value is present and valid.
    /// Then: The configuration should succeed with the expected `UserPoolConfigurationData().endpoint` output.
    func testEndpoint_Valid() throws {
        let validCustomEndpointData = Data(
        """
        {
            "UserAgent": "aws-amplify/cli",
            "Version": "0.1.0",
            "IdentityManager": {
                "Default": {}
            },
            "CredentialsProvider": {
                "CognitoIdentity": {
                    "Default": {
                        "PoolId": "abc",
                        "Region": "us-east-1"
                    }
                }
            },
            "CognitoUserPool": {
                "Default": {
                    "PoolId": "abc",
                    "AppClientId": "abc",
                    "Region": "abc",
                    "Endpoint": "example.com"
                }
            },
            "Auth": {
                "Default": {
                    "authenticationFlowType": "USER_SRP_AUTH",
                    "socialProviders": [],
                    "usernameAttributes": [],
                    "signupAttributes": [
                        "EMAIL"
                    ],
                    "passwordProtectionSettings": {
                        "passwordPolicyMinLength": 8,
                        "passwordPolicyCharacters": []
                    },
                    "mfaConfiguration": "OFF",
                    "mfaTypes": [
                        "SMS"
                    ],
                    "verificationMechanisms": [
                        "EMAIL"
                    ]
                }
            }
        }
        """.utf8
        )
        let config = try JSONDecoder().decode(JSONValue.self, from: validCustomEndpointData)
        let authConfiguration = try ConfigurationHelper.authConfiguration(config)
        let userPoolConfiguration = authConfiguration.getUserPoolConfiguration()
        let endpoint = userPoolConfiguration?.endpoint
        XCTAssertEqual(endpoint?.validatedHost, "example.com")
        XCTAssertEqual(try endpoint?.resolver.endpoint().protocolType, .https)
    }

    /// Given: The `awsCognitoAuthPlugin` portion of an `amplifyconfiguration.json`
    /// When: The `Endpoint` value is present and invalid.
    /// Then: The configuration should fail with the expected `AuthError` thrown.
    func testEndpoint_Invalid() throws {
        let invalidEndpoint = "https://example.com"
        let invalidCustomEndpointData = Data(
            """
            {
                "UserAgent": "aws-amplify/cli",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CredentialsProvider": {
                    "CognitoIdentity": {
                        "Default": {
                            "PoolId": "abc",
                            "Region": "us-east-1"
                        }
                    }
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "abc",
                        "AppClientId": "abc",
                        "Region": "abc",
                        "Endpoint": "\(invalidEndpoint)"
                    }
                },
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH",
                        "socialProviders": [],
                        "usernameAttributes": [],
                        "signupAttributes": [
                            "EMAIL"
                        ],
                        "passwordProtectionSettings": {
                            "passwordPolicyMinLength": 8,
                            "passwordPolicyCharacters": []
                        },
                        "mfaConfiguration": "OFF",
                        "mfaTypes": [
                            "SMS"
                        ],
                        "verificationMechanisms": [
                            "EMAIL"
                        ]
                    }
                }
            }
            """.utf8
        )
        let config = try JSONDecoder().decode(JSONValue.self, from: invalidCustomEndpointData)

        XCTAssertThrowsError(
            try ConfigurationHelper.authConfiguration(config),
            "",
            AuthError.validateConfigurationError
        )
    }
}

extension AuthError {
    static func validateConfigurationError(_ error: Error) {
        guard let authError = error as? AuthError, authError.type == AuthError.configurationError else {
            return XCTFail("Expected error AuthError.configuration")
        }
    }
}
