//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct ClearFederationOperationHelper {

    func clearFederation(_ authStateMachine: AuthStateMachine) async throws {

        let currentState = await authStateMachine.currentState

        guard case .configured(let authNState, let authZState) = currentState else {
            let authError = AuthError.invalidState(
                "Clearing of federation failed.",
                AuthPluginErrorConstants.invalidStateError, nil)
            throw authError
        }

        switch (authNState, authZState) {
        case (.federatedToIdentityPool, .sessionEstablished),
            (.error, .error):
            try await startClearingFederation(with: authStateMachine)
        default:
            let authError = AuthError.invalidState(
                "Clearing of federation failed.",
                AuthPluginErrorConstants.invalidStateError, nil)
            throw authError
        }
    }

    private func startClearingFederation(with authStateMachine: AuthStateMachine) async throws {
        let event = AuthenticationEvent.init(eventType: .clearFederationToIdentityPool)
        await authStateMachine.send(event)
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard  case .configured(let authNState, _) = state else {
                continue
            }

            switch authNState {
            case .signedOut:
                return
            case .error(let error):
                throw error.authError
            default:
                continue
            }
        }
    }

}
