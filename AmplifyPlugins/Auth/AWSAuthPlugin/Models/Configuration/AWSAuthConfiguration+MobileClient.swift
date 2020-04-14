//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

extension AWSAuthConfiguration {

    /// Convert the AWSAuthConfiguration to AWSMobileClient readable configuration
    /// - Returns: Json representation of configuration readable by AWSMobileClient.
    func awsMobileClientConfiguration() -> [String: Any] {
        var awsConfiguration: [String: Any] = [:]
        awsConfiguration["UserAgent"] = "aws-amplify/cli"
        awsConfiguration["Version"] = "0.1.0"

        let defaultIdManager = ["Default": [:]]
        awsConfiguration["IdentityManager"] = defaultIdManager

        // Cognito Identity Pool
        if let cognitoIdentityPoolId = identityPoolId {
            let cognitoIdentityPool = ["PoolId": cognitoIdentityPoolId, "Region": AWSEndpoint.regionName(from: region)]
            let defaultCognitoIdentity = ["Default": cognitoIdentityPool]
            let cognitoIdentity = ["CognitoIdentity": defaultCognitoIdentity]
            awsConfiguration["CredentialsProvider"] = cognitoIdentity
        }

        if let cognitoUserPoolId = userPoolId,
            let cognitoAppClientId = userPoolAppClientId,
            let cognitoClientSecret = userPoolAppClientSecret {

            // Cognito UserPool
            let cognitoUserPool = ["PoolId": cognitoUserPoolId,
                                   "Region": AWSEndpoint.regionName(from: region),
                                   "AppClientId": cognitoAppClientId,
                                   "AppClientSecret": cognitoClientSecret]
            let defaultCognitoUserPool = ["Default": cognitoUserPool]
            awsConfiguration["CognitoUserPool"] = defaultCognitoUserPool

            var auth = ["authenticationFlowType": authenticationFlowType] as [String: Any]
            if let cognitoHostedUIDomain = userPoolHostedUIDomain {
                // Auth
                let oauth = ["WebDomain": cognitoHostedUIDomain,
                            "AppClientId": cognitoAppClientId,
                            "AppClientSecret": cognitoClientSecret,
                            "SignInRedirectURI": signInRedirectURI ?? "",
                            "SignOutRedirectURI": signOutRedirectURI ?? "",
                            "Scopes": hostedUIScopes ?? []] as [String: Any]
                auth["OAuth"] = oauth
            }
            let defaultOauth = ["Default": auth]
            awsConfiguration["Auth"] = defaultOauth
        }
        return awsConfiguration
    }
}
