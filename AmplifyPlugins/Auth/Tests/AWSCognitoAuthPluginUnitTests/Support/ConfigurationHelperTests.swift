//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(InternalAmplifyConfiguration) @testable import Amplify
@testable import AWSCognitoAuthPlugin

final class ConfigurationHelperTests: XCTestCase {

    /// Test parsing the config and verifying the defaults that are set.
    func testParseUserPoolData_Defaults() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            identityPoolId: "identityPoolId",
            standardRequiredAttributes: [.email],
            usernameAttributes: ["EMAIL"],
            userVerificationTypes: ["email"],
            unauthenticatedIdentitiesEnabled: true,
            mfaConfiguration: nil,
            mfaMethods: nil)

        guard let result = try ConfigurationHelper.parseUserPoolData(config) else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.poolId, "poolId")
        XCTAssertEqual(result.clientId, "clientId")
        XCTAssertEqual(result.region, "us-east-1")
        XCTAssertEqual(result.authFlowType, .userSRP)
        XCTAssertNil(result.endpoint)
        XCTAssertNil(result.clientSecret)
        XCTAssertNil(result.pinpointAppId)
    }

    // Testing the OAuth mapping logic, such as taking the first redirect URI in the array.
    func testParseUserPoolData_WithOAuth() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            oauth: AmplifyOutputsData.Auth.OAuth(identityProviders: ["provider1", "provider2"],
                                                 cognitoDomain: "cognitoDomain",
                                                 customDomain: nil,
                                                 scopes: ["scope1", "scope2"],
                                                 redirectSignInUri: ["redirect1", "redirect2"],
                                                 redirectSignOutUri: ["signOut1", "signOut2"],
                                                 responseType: "responseType"))

        guard let config = try ConfigurationHelper.parseUserPoolData(config),
              let hostedUIConfig = config.hostedUIConfig else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }
        
        XCTAssertEqual(hostedUIConfig.clientId, "clientId")
        XCTAssertNil(hostedUIConfig.clientSecret)
        XCTAssertEqual(hostedUIConfig.oauth.scopes, ["scope1", "scope2"])
        XCTAssertEqual(hostedUIConfig.oauth.domain, "cognitoDomain")
        XCTAssertEqual(hostedUIConfig.oauth.signInRedirectURI, "redirect1")
        XCTAssertEqual(hostedUIConfig.oauth.signOutRedirectURI, "signOut1")
    }

    /// Test Oauth section's `customDomain` overwrites `cognitoDomain`
    func testParseUserPoolData_WithOAuth_CustomDomain() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            oauth: AmplifyOutputsData.Auth.OAuth(identityProviders: ["provider1", "provider2"],
                                                 cognitoDomain: "cognitoDomain",
                                                 customDomain: "customDomain",
                                                 scopes: ["scope1", "scope2"],
                                                 redirectSignInUri: ["redirect1", "redirect2"],
                                                 redirectSignOutUri: ["signOut1", "signOut2"],
                                                 responseType: "responseType"))

        guard let config = try ConfigurationHelper.parseUserPoolData(config),
              let hostedUIConfig = config.hostedUIConfig else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(hostedUIConfig.clientId, "clientId")
        XCTAssertNil(hostedUIConfig.clientSecret)
        XCTAssertEqual(hostedUIConfig.oauth.scopes, ["scope1", "scope2"])
        XCTAssertEqual(hostedUIConfig.oauth.domain, "customDomain")
        XCTAssertEqual(hostedUIConfig.oauth.signInRedirectURI, "redirect1")
        XCTAssertEqual(hostedUIConfig.oauth.signOutRedirectURI, "signOut1")
    }

    // Test that password policy is parsed correctly
    func testParseUserPoolData_WithPasswordPolicy() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            passwordPolicy: .init(minLength: 5,
                                  requireNumbers: true,
                                  requireLowercase: true,
                                  requireUppercase: true,
                                  requireSymbols: true))

        guard let config = try ConfigurationHelper.parseUserPoolData(config),
              let result = config.passwordProtectionSettings else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.minLength, 5)
        XCTAssertTrue(result.characterPolicy.contains(.numbers))
        XCTAssertTrue(result.characterPolicy.contains(.lowercase))
        XCTAssertTrue(result.characterPolicy.contains(.uppercase))
        XCTAssertTrue(result.characterPolicy.contains(.symbols))
    }

    // Test that the username attribute is parsed corrctly
    func testParseUserPoolData_WithUsernameAttributes() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            usernameAttributes: ["EMAIL", "PHONE_NUMBER", "USERNAME"])

        guard let result = try ConfigurationHelper.parseUserPoolData(config) else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.usernameAttributes, [.email, .phoneNumber, .username])
    }

    // Test the standard attributes are mapped to sign up attributes correctly.
    func testParseUserPoolData_WithStandardAttributes() throws {
        // Attributes which are commented out are ones that will fail the parsing, and tested separately
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            standardRequiredAttributes: [.address,
                                         .birthdate,
                                         .email,
                                         .familyName,
                                         .gender,
                                         .givenName,
                                         //.locale,
                                         .middleName,
                                         .name,
                                         .nickname,
                                         .phoneNumber,
                                         //.picture,
                                         .preferredUsername,
                                         .profile,
                                         //.sub,
                                         //.updatedAt,
                                         .website,
                                         //.zoneinfo
            ])

        guard let result = try ConfigurationHelper.parseUserPoolData(config) else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.signUpAttributes.count, config.standardRequiredAttributes?.count)
        XCTAssertTrue(result.signUpAttributes.contains(.address))
        XCTAssertTrue(result.signUpAttributes.contains(.birthDate))
        XCTAssertTrue(result.signUpAttributes.contains(.email))
        XCTAssertTrue(result.signUpAttributes.contains(.familyName))
        XCTAssertTrue(result.signUpAttributes.contains(.gender))
        XCTAssertTrue(result.signUpAttributes.contains(.givenName))
        XCTAssertTrue(result.signUpAttributes.contains(.middleName))
        XCTAssertTrue(result.signUpAttributes.contains(.name))
        XCTAssertTrue(result.signUpAttributes.contains(.nickname))
        XCTAssertTrue(result.signUpAttributes.contains(.phoneNumber))
        XCTAssertTrue(result.signUpAttributes.contains(.preferredUsername))
        XCTAssertTrue(result.signUpAttributes.contains(.profile))
        XCTAssertTrue(result.signUpAttributes.contains(.website))
    }

    // Test that missing sign up attributes throw for the corresponding standard attribute.
    func testParseUserPoolData_WithMissingStandardToSignUpAttributeMapping() throws {
        let missingStandardToSignUpAttributes: [AmplifyOutputsData.AmazonCognitoStandardAttributes] =
        [.locale,
         .picture,
         .sub,
         .updatedAt,
         .zoneinfo]
        for attribute in missingStandardToSignUpAttributes {
            let config = AmplifyOutputsData.Auth(
                awsRegion: "us-east-1",
                userPoolId: "poolId",
                userPoolClientId: "clientId",
                standardRequiredAttributes: [attribute])
            do {
                _ = try ConfigurationHelper.parseUserPoolData(config)
            } catch {
                XCTAssertNotNil(error)
                continue
            }
            XCTFail("Should catch and continue with error")
        }
    }

    // Test that the verification mechanisms are parsed correctly.
    func testParseUserPoolData_WithVerificationMechanisms() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            userVerificationTypes: ["PHONE_NUMBER", "EMAIL"])

        guard let result = try ConfigurationHelper.parseUserPoolData(config) else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.verificationMechanisms, [.phoneNumber, .email])
    }
}

