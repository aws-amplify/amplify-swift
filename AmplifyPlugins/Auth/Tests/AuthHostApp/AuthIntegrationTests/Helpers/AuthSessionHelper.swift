//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSCognitoAuthPlugin

struct AuthSessionHelper {

    static func invalidateSessions() {
        let store = CredentialStore(service: "com.amplify.credentialStore")
        try? store.removeAll()
    }
}
