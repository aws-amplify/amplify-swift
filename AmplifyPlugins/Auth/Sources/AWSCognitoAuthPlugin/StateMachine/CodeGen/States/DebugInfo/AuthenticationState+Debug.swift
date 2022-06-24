//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AuthenticationState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {
        case .notConfigured:
            additionalMetadataDictionary = [:]

        case .configured:
            additionalMetadataDictionary = [:]

        case .signingOut(let signOutState):
            additionalMetadataDictionary = signOutState.debugDictionary

        case .signedOut(let signedOutData):
            additionalMetadataDictionary = signedOutData.debugDictionary

        case .signingUp(let signUpState):
            additionalMetadataDictionary = signUpState.debugDictionary

        case .signingIn(let signInState):
            additionalMetadataDictionary = signInState.debugDictionary

        case .signedIn(let signedInData):
            additionalMetadataDictionary = signedInData.debugDictionary
            
        case .deletingUser(let deleteUserState):
            additionalMetadataDictionary = deleteUserState.debugDictionary

        case .error(let error):
            additionalMetadataDictionary = [
                "Error": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }

}
