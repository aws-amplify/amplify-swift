//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignOutState {

    var debugDictionary: [String: Any] {

        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .error(let error):
            additionalMetadataDictionary = ["Error": error]
        default:
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
