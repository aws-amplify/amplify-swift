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
    
    init(_ request: AuthWebUISignInRequest,
         authConfiguration: AuthConfiguration,
         authStateMachine: AuthStateMachine,
         eventName: String
    ) {
        self.request = request
        self.helper = HostedUISignInHelper(request: request,
                                           authstateMachine: authStateMachine,
                                           configuration: authConfiguration)
        super.init(eventName: eventName)
    }
    
    override var value: AuthSignInResult {
        get async throws {
            return try await execute()
        }
    }

    private func execute() async throws -> AuthSignInResult {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<AuthSignInResult, Error>) in
            self?.helper.initiateSignIn { [weak self] result in
                switch result {
                case .success:
                    self?.dispatch(result: result)
                    continuation.resume(with: result)
                case .failure(let error):
                    self?.dispatch(result: result)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
