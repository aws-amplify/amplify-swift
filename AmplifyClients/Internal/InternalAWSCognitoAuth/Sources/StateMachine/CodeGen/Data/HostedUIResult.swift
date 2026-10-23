//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct HostedUIResult {

    package let code: String

    package let state: String

    package let codeVerifier: String

    package let options: HostedUIOptions

    package init(
        code: String,
        state: String,
        codeVerifier: String,
        options: HostedUIOptions
    ) {
        self.code = code
        self.state = state
        self.codeVerifier = codeVerifier
        self.options = options
    }
}

extension HostedUIResult: CustomDebugDictionaryConvertible {

    package var debugDictionary: [String: Any] {
        [
            "code": code.maskedForLog(),
            "state": state.maskedForLog(),
            "codeVerifier": codeVerifier.maskedForLog()
        ]
    }
}

extension HostedUIResult: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
