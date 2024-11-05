//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import typealias Amplify.AuthUIPresentationAnchor
#endif
import Foundation

struct WebAuthnSignInData {
    let username: String
    let presentationAnchor: AuthUIPresentationAnchor?
}

extension WebAuthnSignInData: Equatable {}
