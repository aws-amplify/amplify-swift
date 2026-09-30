//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)

import Amplify
import Foundation
@testable import AWSCognitoAuthPlugin

@available(iOS 17.4, macOS 13.5, *)
// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven
// by a single test at a time.
class MockCredentialRegistrant: CredentialRegistrantProtocol, @unchecked Sendable {
    var presentationAnchor: AuthUIPresentationAnchor?

    var mockedCreateResponse: Result<CredentialRegistrationPayload, Error>?
    // Counted from a `@Sendable` mock closure, so it cannot be a captured `var`.
    let createCallCount = TestCounter()
    func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload {
        createCallCount.increment()
        if let mockedCreateResponse {
            return try mockedCreateResponse.get()
        }

        fatalError("Response for MockCredentialRegistrant.create(with:) not mocked.")
    }
}
#endif
