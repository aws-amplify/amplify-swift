//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

public enum AuthFlowType: String {

    /// Authentication flow for the Secure Remote Password (SRP) protocol
    case userSRP

    /// Authentication flow for custom flow which are backed by lambda triggers
    @available(*, deprecated, message: "Use of custom is deprecated, use customWithSrp or customWithoutSrp instead")
    case custom

    /// Authentication flow which start with SRP and then move to custom auth flow
    case customWithSRP

    /// Authentication flow which starts without SRP and directly moves to custom auth flow
    case customWithoutSRP

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
        case .custom, .customWithSRP, .customWithoutSRP:
            return .customAuth
        case .userSRP, .unknown:
            return .userSrpAuth
        case .userPassword:
            return .userPasswordAuth
        }
    }

}
