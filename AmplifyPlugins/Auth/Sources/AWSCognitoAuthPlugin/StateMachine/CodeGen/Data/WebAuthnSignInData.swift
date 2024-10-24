//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import typealias Amplify.AuthUIPresentationAnchor
import Foundation

struct WebAuthnSignInData {
    let username: String
    private(set) var presentationAnchor: AuthUIPresentationAnchor? = nil

    init(
        username: String,
        presentationAnchor: AuthUIPresentationAnchor? = nil
    ) {
        self.username = username
        self.presentationAnchor = presentationAnchor
    }
}

extension WebAuthnSignInData: Codable {
    private enum CodingKeys: String, CodingKey {
        case username
    }
}

extension WebAuthnSignInData: Equatable {}
