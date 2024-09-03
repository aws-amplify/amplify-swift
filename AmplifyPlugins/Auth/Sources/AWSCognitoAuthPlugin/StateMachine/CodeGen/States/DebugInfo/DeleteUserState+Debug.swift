//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension DeleteUserState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        let additionalMetadataDictionary: [String: Any] = switch self {
        case .notStarted:
            [:]
        case .deletingUser:
            [:]
        case .signingOut(let signedOutState):
            signedOutState.debugDictionary
        case .userDeleted:
            [:]
        case .error(let error):
            [
                "Error": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }

}
