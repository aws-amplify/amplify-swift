//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

struct SignOutEventData {

    let globalSignOut: Bool

    let presentationAnchor: AuthUIPresentationAnchor?

    init(globalSignOut: Bool, presentationAnchor: AuthUIPresentationAnchor? = nil) {
        self.globalSignOut = globalSignOut
        self.presentationAnchor = presentationAnchor
    }
}

extension SignOutEventData: Equatable { }

extension SignOutEventData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "globalSignOut": globalSignOut
        ]
    }
}
extension SignOutEventData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension SignOutEventData: Codable {

    enum CodingKeys: String, CodingKey {

        case globalSignOut
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        globalSignOut = try values.decode(Bool.self, forKey: .globalSignOut)
        presentationAnchor = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(globalSignOut, forKey: .globalSignOut)
    }
}
