//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthClearFederationToIdentityPoolTask: AmplifyAuthTask where Request == AuthClearFederationToIdentityPoolRequest,
                                                                                Success == Void,
                                                                                Failure == AuthError {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let clearedFederationToIdentityPoolAPI = "Auth.federationToIdentityPoolCleared"
}

public class AWSAuthClearFederationToIdentityPoolTask: AuthClearFederationToIdentityPoolTask {
    let authStateMachine: AuthStateMachine
    let clearFederationHelper: ClearFederationOperationHelper
    private var stateMachineToken: AuthStateMachineToken?
    
    public var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.clearedFederationToIdentityPoolAPI
    }

    init(_ request: AuthClearFederationToIdentityPoolRequest, authStateMachine: AuthStateMachine) {
        self.authStateMachine = authStateMachine
        clearFederationHelper = ClearFederationOperationHelper()
    }

    public func execute() async throws {
        await didConfigure()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            clearFederationHelper.clearFederation(authStateMachine) { result in
                switch result {
                case .success:
                    continuation.resume(returning: Void())
                case .failure(let error):
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
