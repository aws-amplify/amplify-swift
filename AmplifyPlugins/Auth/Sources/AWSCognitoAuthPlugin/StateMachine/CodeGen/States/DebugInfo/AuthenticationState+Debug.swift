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

        case .signingOut(let authenticationConfiguration, let signOutState):
            additionalMetadataDictionary = authenticationConfiguration.debugDictionary.merging(
                signOutState.debugDictionary, uniquingKeysWith: {$1}
            )

        case .signedOut(let authenticationConfiguration, let signedOutData):
            additionalMetadataDictionary = authenticationConfiguration.debugDictionary.merging(
                signedOutData.debugDictionary, uniquingKeysWith: {$1}
            )

        case .signingUp(let authenticationConfiguration, let signUpState):
            additionalMetadataDictionary = authenticationConfiguration.debugDictionary.merging(
                signUpState.debugDictionary, uniquingKeysWith: {$1}
            )

        case .signingIn(let authenticationConfiguration, let signInState):
            additionalMetadataDictionary = authenticationConfiguration.debugDictionary.merging(
                signInState.debugDictionary, uniquingKeysWith: {$1}
            )

        case .signedIn(let authenticationConfiguration, let signedInData):
            additionalMetadataDictionary = authenticationConfiguration.debugDictionary.merging(
                signedInData.debugDictionary, uniquingKeysWith: {$1}
            )

        case .error(_, let error):
            additionalMetadataDictionary = [
                "Error": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }

}
