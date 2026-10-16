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
            "answer": answer.maskedForLog(),
            "attributes": attributes,
            "metadata": metadata ?? [:]
        ]
    }
}
extension ConfirmSignInEventData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
