//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignOutState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any] = switch self {
        case .error(let error):
            ["Error": error]
        default:
            [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
