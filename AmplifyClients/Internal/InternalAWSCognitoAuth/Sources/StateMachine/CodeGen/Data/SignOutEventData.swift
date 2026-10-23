//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct SignOutEventData {

    package let globalSignOut: Bool

    package let presentationAnchor: EnginePresentationAnchor?

    /// Skips the hosted-UI sign-out (the browser round trip to the logout endpoint) for a hosted-UI
    /// session, and goes straight to the global sign-out or the token revocation. The plugin always
    /// passes `false`. `AmplifyCognitoClient` passes `true` until it presents web UI itself: it
    /// has no presentation anchor to give, and must never present a browser from a sign-out.
    /// Not encoded: an in-flight event is never persisted with it.
    package let skipHostedUISignOut: Bool

    package init(
        globalSignOut: Bool,
        presentationAnchor: EnginePresentationAnchor? = nil,
        skipHostedUISignOut: Bool = false
    ) {
        self.globalSignOut = globalSignOut
        self.presentationAnchor = presentationAnchor
        self.skipHostedUISignOut = skipHostedUISignOut
    }
}

extension SignOutEventData: Equatable { }

extension SignOutEventData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "globalSignOut": globalSignOut
        ]
    }
}
extension SignOutEventData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension SignOutEventData: Codable {

    enum CodingKeys: String, CodingKey {

        case globalSignOut
    }

    package init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.globalSignOut = try values.decode(Bool.self, forKey: .globalSignOut)
        self.presentationAnchor = nil
        self.skipHostedUISignOut = false

    }

    package func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(globalSignOut, forKey: .globalSignOut)
    }
}
