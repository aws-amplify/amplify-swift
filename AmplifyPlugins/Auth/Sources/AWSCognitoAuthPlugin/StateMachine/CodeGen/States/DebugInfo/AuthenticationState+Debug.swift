//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AuthenticationState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        let additionalMetadataDictionary: [String: Any] = switch self {
        case .notConfigured:
            [:]

        case .configured:
            [:]

        case .signingOut(let signOutState):
            signOutState.debugDictionary

        case .signedOut(let signedOutData):
            signedOutData.debugDictionary

        case .signingIn(let signInState):
            signInState.debugDictionary

        case .signedIn(let signedInData):
            signedInData.debugDictionary

        case .federatedToIdentityPool, .clearingFederation, .federatingToIdentityPool:
            [:]

        case .deletingUser(_, let deleteUserState):
            deleteUserState.debugDictionary

        case .error(let error):
            [
                "Error": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }

}
