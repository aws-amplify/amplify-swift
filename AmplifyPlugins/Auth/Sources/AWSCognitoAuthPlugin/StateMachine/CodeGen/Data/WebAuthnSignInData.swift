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
    let presentationAnchor: AuthUIPresentationAnchor?
}

extension WebAuthnSignInData: Equatable {}
