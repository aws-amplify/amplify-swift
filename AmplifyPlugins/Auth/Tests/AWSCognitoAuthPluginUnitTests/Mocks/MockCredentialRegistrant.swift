//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)

import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation

@available(iOS 17.4, macOS 13.5, *)
class MockCredentialRegistrant: CredentialRegistrantProtocol {
    var presentationAnchor: AuthUIPresentationAnchor?

    var mockedCreateResponse: Result<CredentialRegistrationPayload, Error>?
    var createCallCount = 0
    func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload {
        createCallCount += 1
        if let mockedCreateResponse {
            return try mockedCreateResponse.get()
        }

        fatalError("Response for MockCredentialRegistrant.create(with:) not mocked.")
    }
}
#endif
