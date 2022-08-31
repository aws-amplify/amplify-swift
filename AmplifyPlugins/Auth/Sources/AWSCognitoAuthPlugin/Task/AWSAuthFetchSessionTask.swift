//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthFetchSessionTask: AuthFetchSessionTask {
    private let request: AuthFetchSessionRequest
    private let authStateMachine: AuthStateMachine
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    private var stateMachineToken: AuthStateMachineToken?
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.fetchSessionAPI
    }

    init(_ request: AuthFetchSessionRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func execute() async throws -> AuthSession {
        await didConfigure()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthSession, Error>) in
            let doesNeedForceRefresh = request.options.forceRefresh
            fetchAuthSessionHelper.fetch( authStateMachine, forceRefresh: doesNeedForceRefresh) {result in
                do {
                    let session = try result.get()
                    continuation.resume(returning: session)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func didConfigure() async {
        await withCheckedContinuation { [weak self] (continuation: CheckedContinuation<Void, Never>) in
            stateMachineToken = authStateMachine.listen({ [weak self] state in
                guard let self = self, case .configured = state else { return }
                self.authStateMachine.cancel(listenerToken: self.stateMachineToken!)
                continuation.resume()
            }, onSubscribe: {})
        }
    }
}
