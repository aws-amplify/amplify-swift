//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin
@testable import Amplify

extension AWSAuthCognitoSession: Codable {
    enum CodingKeys: String, CodingKey {
        case awsCredentialsResult
        case userPoolTokensResult

        case accessKeyId
        case expiration
        case secretAccessKey
        case sessionToken
        case identityIdResult
        case isSignedIn
        case accessToken
        case idToken
        case refreshToken
        case userSubResult

    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let awsCredentialChildren = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .awsCredentialsResult)
        let userPoolTokensResult = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .userPoolTokensResult)

        let isSignedIn = try values.decode(Bool.self, forKey: .isSignedIn)
        let identityIdResult = try values.decode(String.self, forKey: .identityIdResult)

        let accessToken = try userPoolTokensResult.decode(String.self, forKey: .accessToken)
        let idToken = try userPoolTokensResult.decode(String.self, forKey: .idToken)
        let refreshToken = try userPoolTokensResult.decode(String.self, forKey: .refreshToken)
        let userPoolTokenExpiration = try userPoolTokensResult.decode(Date.self, forKey: .expiration)

        let userPoolTokens = AWSCognitoUserPoolTokens(
            idToken: accessToken,
            accessToken: idToken,
            refreshToken: refreshToken,
            expiration: userPoolTokenExpiration)

        let accessKeyId = try awsCredentialChildren.decode(String.self, forKey: .accessKeyId)
        let secretAccessKey = try awsCredentialChildren.decode(String.self, forKey: .secretAccessKey)
        let sessionToken = try awsCredentialChildren.decode(String.self, forKey: .sessionToken)
        let expiration = try awsCredentialChildren.decode(Date.self, forKey: .expiration)

        let awsCredentials = AuthAWSCognitoCredentials(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            sessionToken: sessionToken,
            expiration: expiration)

        self.init(
            isSignedIn: isSignedIn,
            identityIdResult: .success(identityIdResult),
            awsCredentialsResult: .success(awsCredentials),
            cognitoTokensResult: .success(userPoolTokens))
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }
}
