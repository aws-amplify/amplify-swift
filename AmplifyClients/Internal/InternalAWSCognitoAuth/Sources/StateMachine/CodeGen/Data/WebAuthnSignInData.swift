//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct WebAuthnSignInData {
    package let username: String
    package let presentationAnchor: EnginePresentationAnchor?

    package init(
        username: String,
        presentationAnchor: EnginePresentationAnchor?
    ) {
        self.username = username
        self.presentationAnchor = presentationAnchor
    }
}

extension WebAuthnSignInData: Equatable {}
