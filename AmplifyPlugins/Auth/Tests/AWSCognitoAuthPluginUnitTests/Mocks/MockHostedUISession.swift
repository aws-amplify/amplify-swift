//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: `HostedUISessionBehavior` is `Sendable` now. Test double with `let` state.
final class MockHostedUISession: HostedUISessionBehavior, @unchecked Sendable {

    let result: Result<[URLQueryItem], HostedUIError>

    init(result: Result<[URLQueryItem], HostedUIError>) {
        self.result = result
    }

    func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: AuthUIPresentationAnchor?
    ) async throws -> [URLQueryItem] {
        return try result.get()
    }

}
