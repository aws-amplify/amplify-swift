//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension WebAuthnSignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any]

        switch self {
        case .notStarted:
            additionalMetadataDictionary = [:]
        case .fetchingCredentialOptions:
            additionalMetadataDictionary = [:]
        case .assertingCredentials:
            additionalMetadataDictionary = [:]
        case .verifyingCredentialsAndSigningIn:
            additionalMetadataDictionary = [:]
        case .error(let error, _):
            additionalMetadataDictionary = ["Error": error]
        case .signedIn(let signedInData):
            additionalMetadataDictionary = ["SignedInData": signedInData.debugDictionary]
        }

        return [type: additionalMetadataDictionary]
    }
}
