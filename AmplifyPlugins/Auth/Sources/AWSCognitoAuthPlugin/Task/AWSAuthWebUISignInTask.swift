//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthWebUISignInTask: AuthWebUISignInTask {

    private let helper: HostedUISignInHelper
    private let request: AuthWebUISignInRequest
    
    let eventName: HubPayloadEventName
    init(_ request: AuthWebUISignInRequest,
         authConfiguration: AuthConfiguration,
         authStateMachine: AuthStateMachine,
         eventName: String
    ) {
        self.request = request
        self.helper = HostedUISignInHelper(request: request,
                                           authstateMachine: authStateMachine,
                                           configuration: authConfiguration)
        self.eventName = eventName
    }

    func execute() async throws -> AuthSignInResult {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<AuthSignInResult, Error>) in
            self?.helper.initiateSignIn { result in
                switch result {
                case .success:
                    continuation.resume(with: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
