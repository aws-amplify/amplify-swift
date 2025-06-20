//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SmithyHTTPAPI
@testable import AWSCognitoAuthPlugin

class UserPoolConfigurationDataTests: XCTestCase {

    /// Test that two UserPoolConfigurationData instances with the same core fields but different endpoints are considered equal
    ///
    /// - Given: Two UserPoolConfigurationData instances with identical core fields but different endpoints
    /// - When: Comparing them for equality
    /// - Then: They should be considered equal (endpoint is excluded from equality)
    func testEquality_IgnoresEndpointDifferences() throws {
        let baseConfig = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId",
            region: "us-east-1",
            endpoint: nil,
            clientSecret: "testSecret",
            pinpointAppId: "testPinpoint"
        )
        
        let configWithEndpoint = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId", 
            region: "us-east-1",
            endpoint: UserPoolConfigurationData.CustomEndpoint(
                endpoint: "idp.example.com",
                validator: { endpoint in
                    return SmithyHTTPAPI.Endpoint(host: endpoint)
                }
            ),
            clientSecret: "testSecret",
            pinpointAppId: "testPinpoint"
        )
        
        // These should be equal despite different endpoints
        XCTAssertEqual(baseConfig, configWithEndpoint)
    }
    
    /// Test that two UserPoolConfigurationData instances with different core fields are not equal
    ///
    /// - Given: Two UserPoolConfigurationData instances with different poolIds
    /// - When: Comparing them for equality  
    /// - Then: They should not be considered equal
    func testEquality_DetectsCoreFieldDifferences() throws {
        let config1 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool1",
            clientId: "testClientId",
            region: "us-east-1",
            clientSecret: "testSecret"
        )
        
        let config2 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool2", // Different poolId
            clientId: "testClientId",
            region: "us-east-1", 
            clientSecret: "testSecret"
        )
        
        // These should not be equal due to different poolIds
        XCTAssertNotEqual(config1, config2)
    }
    
    /// Test that differences in excluded fields don't affect equality
    ///
    /// - Given: Two UserPoolConfigurationData instances with same core fields but different excluded fields
    /// - When: Comparing them for equality
    /// - Then: They should be considered equal (excluded fields are ignored)
    func testEquality_IgnoresExcludedFields() throws {
        let config1 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId",
            region: "us-east-1",
            endpoint: nil,
            clientSecret: "testSecret",
            pinpointAppId: "pinpoint1",
            authFlowType: .userSRP,
            passwordProtectionSettings: nil,
            usernameAttributes: [.email],
            signUpAttributes: [.email],
            verificationMechanisms: [.email]
        )
        
        let config2 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId", 
            region: "us-east-1",
            endpoint: UserPoolConfigurationData.CustomEndpoint(
                endpoint: "idp.example.com",
                validator: { endpoint in
                    return SmithyHTTPAPI.Endpoint(host: endpoint)
                }
            ),
            clientSecret: "testSecret",
            pinpointAppId: "pinpoint2", // Different pinpointAppId
            authFlowType: .userPassword, // Different authFlowType
            usernameAttributes: [.phoneNumber], // Different usernameAttributes
            signUpAttributes: [.phoneNumber], // Different signUpAttributes
            verificationMechanisms: [.phoneNumber] // Different verificationMechanisms
        )
        
        // These should be equal despite differences in excluded fields
        XCTAssertEqual(config1, config2)
    }
    
    /// Test that clientId differences are detected
    ///
    /// - Given: Two UserPoolConfigurationData instances with different clientIds
    /// - When: Comparing them for equality
    /// - Then: They should not be considered equal
    func testEquality_DetectsClientIdDifferences() throws {
        let config1 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId1",
            region: "us-east-1",
            clientSecret: "testSecret"
        )
        
        let config2 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId2", // Different clientId
            region: "us-east-1",
            clientSecret: "testSecret"
        )
        
        XCTAssertNotEqual(config1, config2)
    }
    
    /// Test that region differences are detected
    ///
    /// - Given: Two UserPoolConfigurationData instances with different regions
    /// - When: Comparing them for equality
    /// - Then: They should not be considered equal
    func testEquality_DetectsRegionDifferences() throws {
        let config1 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId",
            region: "us-east-1",
            clientSecret: "testSecret"
        )
        
        let config2 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId",
            region: "us-west-2", // Different region
            clientSecret: "testSecret"
        )
        
        XCTAssertNotEqual(config1, config2)
    }
    
    /// Test that clientSecret differences are detected
    ///
    /// - Given: Two UserPoolConfigurationData instances with different clientSecrets
    /// - When: Comparing them for equality
    /// - Then: They should not be considered equal  
    func testEquality_DetectsClientSecretDifferences() throws {
        let config1 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId", 
            region: "us-east-1",
            clientSecret: "testSecret1"
        )
        
        let config2 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId",
            region: "us-east-1", 
            clientSecret: "testSecret2" // Different clientSecret
        )
        
        XCTAssertNotEqual(config1, config2)
    }
    
    /// Test that hostedUIConfig differences are detected
    ///
    /// - Given: Two UserPoolConfigurationData instances with different hostedUIConfigs
    /// - When: Comparing them for equality
    /// - Then: They should not be considered equal
    func testEquality_DetectsHostedUIConfigDifferences() throws {
        let hostedUIConfig1 = HostedUIConfigurationData(
            clientId: "testClientId",
            oauth: .init(
                domain: "domain1.com",
                scopes: ["openid"],
                signInRedirectURI: "myapp://signin",
                signOutRedirectURI: "myapp://signout"
            ), clientSecret: nil
        )
        
        let hostedUIConfig2 = HostedUIConfigurationData(
            clientId: "testClientId",
            oauth: .init(
                domain: "domain2.com", // Different domain
                scopes: ["openid"],
                signInRedirectURI: "myapp://signin",
                signOutRedirectURI: "myapp://signout"
            ), clientSecret: nil
        )
        
        let config1 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId",
            region: "us-east-1",
            clientSecret: "testSecret",
            hostedUIConfig: hostedUIConfig1
        )
        
        let config2 = UserPoolConfigurationData(
            poolId: "us-east-1_testPool",
            clientId: "testClientId",
            region: "us-east-1",
            clientSecret: "testSecret",
            hostedUIConfig: hostedUIConfig2
        )
        
        XCTAssertNotEqual(config1, config2)
    }
} 
