//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension HostedUISignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {
        case .notStarted:
            additionalMetadataDictionary = [:]
        default:
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }

}
