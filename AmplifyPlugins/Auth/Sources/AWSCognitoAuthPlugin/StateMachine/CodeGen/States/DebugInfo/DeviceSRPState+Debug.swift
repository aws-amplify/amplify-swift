//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DeviceSRPState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any] = switch self {
        case .notStarted:
            [:]
        case .initiatingDeviceSRP:
            [:]
        case .cancelling:
            [:]
        case .respondingDevicePasswordVerifier(let srpStateData):
            srpStateData.debugDictionary
        case .signedIn(let signedInData):
            signedInData.debugDictionary
        case .error(let error):
            [
                "Error": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }
}
