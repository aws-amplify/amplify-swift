//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct ConfirmSignInEventData {

    package let answer: String
    package let attributes: [String: String]
    package let metadata: [String: String]?
    package let friendlyDeviceName: String?
    package let presentationAnchor: EnginePresentationAnchor?

    package init(
        answer: String,
        attributes: [String: String],
        metadata: [String: String]?,
        friendlyDeviceName: String?,
        presentationAnchor: EnginePresentationAnchor?
    ) {
        self.answer = answer
        self.attributes = attributes
        self.metadata = metadata
        self.friendlyDeviceName = friendlyDeviceName
        self.presentationAnchor = presentationAnchor
    }
}

extension ConfirmSignInEventData: Equatable { }

extension ConfirmSignInEventData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "answer": answer.redactedForLog(),
            "attributes": attributes,
            "metadata": metadata ?? [:]
        ]
    }
}

// Every printed form redacts the answer, the user's code, password or custom answer: the answer rides in the
// challenge and TOTP setup events, which a "Sending event" line prints, and in the TOTP setup state the sign-in's
// verbose lines print. A masked answer kept four characters of a six-digit code.
extension ConfirmSignInEventData: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    package var description: String {
        debugDictionary.debugDescription
    }

    package var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the answer redacted.
    package var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "answer": answer.redactedForLog(),
                "attributes": attributes,
                "metadata": metadata as Any,
                "friendlyDeviceName": friendlyDeviceName as Any,
                "presentationAnchor": presentationAnchor as Any
            ],
            displayStyle: .struct
        )
    }
}
