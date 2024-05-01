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
            usernameAttributes: [.email],
            userVerificationTypes: [.email],
            unauthenticatedIdentitiesEnabled: true,
            mfaConfiguration: nil,
            mfaMethods: nil)

        guard let result = ConfigurationHelper.parseUserPoolData(config) else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.poolId, "poolId")
        XCTAssertEqual(result.clientId, "clientId")
        XCTAssertEqual(result.region, "us-east-1")
        XCTAssertEqual(result.authFlowType, .userSRP)
        XCTAssertNil(result.endpoint, "Gen2 currently does not support custom endpoints")
        XCTAssertNil(result.clientSecret, "Gen2 currently does not support using client secret")
        XCTAssertNil(result.pinpointAppId, "Gen2 currently does not support automatically sending auth events through Pinpoint.")
    }

    /// Testing the OAuth mapping logic, such as taking the first redirect URI in the array.
    func testParseUserPoolData_WithOAuth() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            oauth: AmplifyOutputsData.Auth.OAuth(identityProviders: ["provider1", "provider2"],
                                                 domain: "domain",
                                                 scopes: ["scope1", "scope2"],
                                                 redirectSignInUri: ["redirect1", "redirect2"],
                                                 redirectSignOutUri: ["signOut1", "signOut2"],
                                                 responseType: "responseType"))

        guard let config = ConfigurationHelper.parseUserPoolData(config),
              let hostedUIConfig = config.hostedUIConfig else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }
        
        XCTAssertEqual(hostedUIConfig.clientId, "clientId")
        XCTAssertNil(hostedUIConfig.clientSecret, "Client secret should be nil as its not supported in Gen2")
        XCTAssertEqual(hostedUIConfig.oauth.scopes, ["scope1", "scope2"])
        XCTAssertEqual(hostedUIConfig.oauth.domain, "domain")
        XCTAssertEqual(hostedUIConfig.oauth.signInRedirectURI, "redirect1")
        XCTAssertEqual(hostedUIConfig.oauth.signOutRedirectURI, "signOut1")
    }

    /// Test that password policy is parsed correctly
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

        guard let config = ConfigurationHelper.parseUserPoolData(config),
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

    /// Test that the username attribute is parsed corrctly
    func testParseUserPoolData_WithUsernameAttributes() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            usernameAttributes: [.email, .phoneNumber])

        guard let result = ConfigurationHelper.parseUserPoolData(config) else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.usernameAttributes, [.email, .phoneNumber])
    }

    func testParseUserPoolData_WithStandardAttributes() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            standardRequiredAttributes: [
                .address,
                .birthdate,
                .email,
                .familyName,
                .gender,
                .givenName,
                .middleName,
                .name,
                .nickname,
                .phoneNumber,
                .preferredUsername,
                .profile,
                .website
            ])

        guard let result = ConfigurationHelper.parseUserPoolData(config) else {
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

    /// Test that some sign up attributes do not correspond to any standard attribute.
    func testParseUserPoolData_WithMissingStandardToSignUpAttributeMapping() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            standardRequiredAttributes: [
                .locale,
                .picture,
                .sub,
                .updatedAt,
                .zoneinfo
            ])

        guard let result = ConfigurationHelper.parseUserPoolData(config) else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.signUpAttributes.count, 0)
    }

    /// Test that the verification mechanisms are parsed correctly.
    func testParseUserPoolData_WithVerificationMechanisms() throws {
        let config = AmplifyOutputsData.Auth(
            awsRegion: "us-east-1",
            userPoolId: "poolId",
            userPoolClientId: "clientId",
            userVerificationTypes: [.phoneNumber, .email])

        guard let result = ConfigurationHelper.parseUserPoolData(config) else {
            XCTFail("Expected to parse UserPoolData into object")
            return
        }

        XCTAssertEqual(result.verificationMechanisms, [.phoneNumber, .email])
    }

    // MARK: - `createUserPoolJsonConfiguration` tests

    /// Test that the AuthConfiguration can be translated back to the expected JSON
    /// for the authenticator to parse.
    func testCreateUserPoolJsonConfiguration() throws {
        let config = AuthConfiguration
            .userPools(.init(
                poolId: "",
                clientId: "", 
                region: "",
                passwordProtectionSettings: .init(from: .init(
                    minLength: 8,
                    requireNumbers: true,
                    requireLowercase: true,
                    requireUppercase: true,
                    requireSymbols: true)), 
                usernameAttributes: [
                    .init(from: .email),
                    .init(from: .phoneNumber)
                ],
                signUpAttributes: [
                    .init(from: .email)!,
                    .init(from: .address)!,
                ],
                verificationMechanisms: [
                    .init(from: .email),
                    .init(from: .phoneNumber)
                ]))
        let json = ConfigurationHelper.createUserPoolJsonConfiguration(config)

        guard let authConfig = json.Auth?.Default else {
            XCTFail("Could not retrieve auth configuration from json")
            return
        }

        XCTAssertEqual(authConfig.passwordProtectionSettings?.passwordPolicyMinLength, 8)
        guard let passwordPolicyCharacters = authConfig.passwordProtectionSettings?.passwordPolicyCharacters?.asArray else {
            XCTFail("Could not retrieve passwordPolicyCharacters from json")
            return
        }
        XCTAssertTrue(passwordPolicyCharacters.contains("REQUIRES_LOWERCASE"))
        XCTAssertTrue(passwordPolicyCharacters.contains("REQUIRES_UPPERCASE"))
        XCTAssertTrue(passwordPolicyCharacters.contains("REQUIRES_NUMBERS"))
        XCTAssertTrue(passwordPolicyCharacters.contains("REQUIRES_SYMBOLS"))

        guard let usernameAttributes = authConfig.usernameAttributes?.asArray else {
            XCTFail("Could not retrieve usernameAttributes from json")
            return
        }

        XCTAssertEqual(usernameAttributes.count, 2)
        XCTAssertTrue(usernameAttributes.contains("EMAIL"))
        XCTAssertTrue(usernameAttributes.contains("PHONE_NUMBER"))

        guard let signupAttributes = authConfig.signupAttributes?.asArray else {
            XCTFail("Could not retrieve signupAttributes from json")
            return
        }

        XCTAssertEqual(signupAttributes.count, 2)
        XCTAssertTrue(signupAttributes.contains("EMAIL"))
        XCTAssertTrue(signupAttributes.contains("ADDRESS"))

        guard let verificationMechanism = authConfig.verificationMechanism?.asArray else {
            XCTFail("Could not retrieve verificationMechanism from json")
            return
        }

        XCTAssertEqual(verificationMechanism.count, 2)
        XCTAssertTrue(verificationMechanism.contains("EMAIL"))
        XCTAssertTrue(verificationMechanism.contains("PHONE_NUMBER"))
    }
}

