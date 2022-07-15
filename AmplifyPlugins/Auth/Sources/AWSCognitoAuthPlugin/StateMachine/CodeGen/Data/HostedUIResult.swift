//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct HostedUIResult {

    let code: String

    let state: String

    let codeVerifier: String

    let options: HostedUIOptions
}

extension HostedUIResult: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        [
            "code": code.masked(),
            "state": state.masked(),
            "codeVerifier": codeVerifier.masked()
        ]
    }
}

extension HostedUIResult: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
