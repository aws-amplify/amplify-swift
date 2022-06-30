//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension DeleteUserState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {
        case .notStarted:
            additionalMetadataDictionary = [:]
        case .deletingUser:
            additionalMetadataDictionary = [:]
        case .signingOut(let signedOutState):
            additionalMetadataDictionary = signedOutState.debugDictionary
        case .userDeleted:
            additionalMetadataDictionary = [:]
        case .error(let error):
            additionalMetadataDictionary = [
                "Error": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }
    
}
