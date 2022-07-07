//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import AWSCognitoIdentityProvider

public struct AWSAuthSignInOptions {

    public let authFlowType: AuthFlowType

    public let validationData: [String: String]?

    public let metadata: [String: String]?

    public init(validationData: [String: String]? = nil,
                metadata: [String: String]? = nil,
                authFlowType: AuthFlowType = .unknown) {
        self.validationData = validationData
        self.metadata = metadata
        self.authFlowType = authFlowType
    }
}

public enum AuthFlowType: String {

    /// Authentication flow for the Secure Remote Password (SRP) protocol
    case userSRP

    /// Authentication flow for custom flow which are backed by lambda triggers
    case custom

    /// Authentication flow which start with SRP and then move to custom auth flow
    case customWithSRP

    /// Non-SRP authentication flow; user name and password are passed directly.
    /// If a user migration Lambda trigger is set, this flow will invoke the user migration
    /// Lambda if it doesn't find the user name in the user pool.
    case userPassword

    case unknown
}

extension AuthFlowType: Codable { }

extension AuthFlowType {

    func getClientFlowType() -> CognitoIdentityProviderClientTypes.AuthFlowType {
        switch self {
        case .custom, .customWithSRP:
            return .customAuth
        case .userSRP, .unknown:
            return .userSrpAuth
        default:
            fatalError("Flow Type not supported")
        }
    }

}
