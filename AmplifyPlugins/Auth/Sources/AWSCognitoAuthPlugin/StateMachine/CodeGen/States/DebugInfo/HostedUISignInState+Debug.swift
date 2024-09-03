//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension HostedUISignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        let additionalMetadataDictionary: [String: Any] = switch self {
        case .notStarted:
            [:]
        case .error(let error):
            ["error": error]
        default:
            [:]
        }
        return [type: additionalMetadataDictionary]
    }

}
