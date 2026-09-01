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
    // Boxed: incremented from a `@Sendable` mock closure.
    let createCallCount = AtomicValue(initialValue: 0)
    func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload {
        _ = createCallCount.increment()
        if let mockedCreateResponse {
            return try mockedCreateResponse.get()
        }

        fatalError("Response for MockCredentialRegistrant.create(with:) not mocked.")
    }
}
#endif
