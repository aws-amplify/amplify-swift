//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol LoginsMapProvider {

    var loginsMap: [String: String] { get }
}

struct UnAuthLoginsMapProvider: LoginsMapProvider {

    let loginsMap: [String: String] = [:]
}

struct CognitoUserPoolLoginsMap: LoginsMapProvider {

    let idToken: String
    let region: String
    let poolId: String

    var loginsMap: [String: String] { [providerName: idToken] }

    var providerName: String {
        "cognito-idp.\(region).amazonaws.com/\(poolId)"
    }
}

struct AuthProviderLoginsMap: LoginsMapProvider {

    let federatedToken: FederatedToken

    var loginsMap: [String : String] {
        [federatedToken.provider.providerName: federatedToken.token]
    }
}
