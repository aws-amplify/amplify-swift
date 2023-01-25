//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import Foundation

extension AuthorizationState: Codable {

    enum CodingKeys: String, CodingKey {
        case type
        case amplifyCredential

        case signedInData

        case credentials
        case cognitoUserPoolTokens

        case accessKeyId
        case expiration
        case secretAccessKey
        case sessionToken

        case identityId

        case accessToken
        case idToken
        case refreshToken
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        if type == "AuthorizationState.SessionEstablished" {

            let rootAmplifyCredentialParent = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .amplifyCredential)

            let signedInDataParent = try rootAmplifyCredentialParent.nestedContainer(keyedBy: CodingKeys.self, forKey: .signedInData)

            let awsCredentialChildren = try rootAmplifyCredentialParent.nestedContainer(keyedBy: CodingKeys.self, forKey: .credentials)
            let cognitoUserPoolTokens = try signedInDataParent.nestedContainer(keyedBy: CodingKeys.self, forKey: .cognitoUserPoolTokens)


            let identityId = try rootAmplifyCredentialParent.decode(String.self, forKey: .identityId)

            let accessToken = try cognitoUserPoolTokens.decode(String.self, forKey: .accessToken)
            let idToken = try cognitoUserPoolTokens.decode(String.self, forKey: .idToken)
            let refreshToken = try cognitoUserPoolTokens.decode(String.self, forKey: .refreshToken)
            let userPoolExpiration = try cognitoUserPoolTokens.decode(Date.self, forKey: .expiration)

            let userPoolTokens = AWSCognitoUserPoolTokens(
                idToken: accessToken,
                accessToken: idToken,
                refreshToken: refreshToken,
                expiration: userPoolExpiration)

            let accessKeyId = try awsCredentialChildren.decode(String.self, forKey: .accessKeyId)
            let secretAccessKey = try awsCredentialChildren.decode(String.self, forKey: .secretAccessKey)
            let sessionToken = try awsCredentialChildren.decode(String.self, forKey: .sessionToken)
            let expiration = try awsCredentialChildren.decode(Date.self, forKey: .expiration)

            let awsCredentials = AuthAWSCognitoCredentials(
                accessKeyId: accessKeyId,
                secretAccessKey: secretAccessKey,
                sessionToken: sessionToken,
                expiration: expiration)

            self = .sessionEstablished(.userPoolAndIdentityPool(
                signedInData: .init(
                    signedInDate: Date(),
                    signInMethod: .apiBased(.userSRP),
                    cognitoUserPoolTokens: userPoolTokens),
                identityID: identityId,
                credentials: awsCredentials))




        } else if type == "AuthorizationState.Configured" {
            self = .configured
        } else {
            fatalError("Decoding not supported")
        }

    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        default:
            fatalError()
        }
    }
}
