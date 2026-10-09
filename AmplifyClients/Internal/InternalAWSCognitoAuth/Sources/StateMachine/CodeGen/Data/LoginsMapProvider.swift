//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `Sendable` because logins maps are carried on state machine states, which are `Sendable`.
package protocol LoginsMapProvider: Sendable {

    var loginsMap: [String: String] { get }
}

package struct UnAuthLoginsMapProvider: LoginsMapProvider {

    package let loginsMap: [String: String] = [:]

    package init() {}
}

package struct CognitoUserPoolLoginsMap: LoginsMapProvider {

    package let idToken: String
    package let region: String
    package let poolId: String

    package var loginsMap: [String: String] { [providerName: idToken] }

    package var providerName: String {
        "cognito-idp.\(region).amazonaws.com/\(poolId)"
    }

    package init(
        idToken: String,
        region: String,
        poolId: String
    ) {
        self.idToken = idToken
        self.region = region
        self.poolId = poolId
    }
}

package struct AuthProviderLoginsMap: LoginsMapProvider {

    package let federatedToken: FederatedToken

    package var loginsMap: [String: String] {
        [federatedToken.provider.identityPoolProviderName: federatedToken.token]
    }

    package init(federatedToken: FederatedToken) {
        self.federatedToken = federatedToken
    }
}
