//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol AuthFederateToIdentityPoolTask: AmplifyAuthTask where Request == AuthFederateToIdentityPoolRequest,
                                                               Success == FederateToIdentityPoolResult,
                                                               Failure == AuthError {}

public extension HubPayload.EventName.Auth {
    /// eventName for HubPayloads emitted by this operation
    static let federateToIdentityPoolAPI = "Auth.federatedToIdentityPool"
}

public class AWSAuthFederateToIdentityPoolTask: AuthFederateToIdentityPoolTask {

    private let request: AuthFederateToIdentityPoolRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    
    public var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.federateToIdentityPoolAPI
    }

    init(_ request: AuthFederateToIdentityPoolRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    public func execute() async throws -> FederateToIdentityPoolResult {
        await taskHelper.didStateMachineConfigured()
        let state = await authStateMachine.currentState
        guard case .configured(let authNState, let authZState) = state  else {
            throw AuthError.invalidState(
                "Federation could not be completed.",
                AuthPluginErrorConstants.invalidStateError, nil)
        }

        if isValidAuthNStateToStart(authNState) && isValidAuthZStateToStart(authZState) {
            // Clear previous federation before beginning a new one
            if case .federatedToIdentityPool = authNState {
                try await clearPreviousFederation()
            }
            return try await startFederatingToIdentityPool()
        } else {
            throw AuthError.invalidState(
                "Federation could not be completed.",
                AuthPluginErrorConstants.invalidStateError, nil)
        }
    }

    func clearPreviousFederation() async throws {
        let clearFederationHelper = ClearFederationOperationHelper()
        try await clearFederationHelper.clearFederation(authStateMachine)
    }

    func startFederatingToIdentityPool() async throws -> FederateToIdentityPoolResult {

        let stateSequences = await authStateMachine.listen()
        await sendStartFederatingToIdentityPoolEvent()
        for await state in stateSequences {
            guard  case .configured(let authNState, let authZState) = state else {
                continue
            }

            switch (authNState, authZState) {
            case (.federatedToIdentityPool, .sessionEstablished(let credentials)):
                return try getFederatedResult(credentials)
            case (.error(_), .error(let authZError)):
                throw authZError.authError
            default:
                continue
            }
        }
        throw AuthError.unknown("Could not start federation to Identity Pool")
    }

    func sendStartFederatingToIdentityPoolEvent() async {
        let federatedToken = FederatedToken(token: request.token, provider: request.provider)
        let identityId = request.options.developerProvidedIdentityID
        let event = AuthorizationEvent.init( eventType: .startFederationToIdentityPool(federatedToken, identityId))
        await authStateMachine.send(event)
    }

    func isValidAuthNStateToStart(_ authNState: AuthenticationState) -> Bool {
        switch authNState {
        case .notConfigured, .signedOut, .federatedToIdentityPool, .error:
            return true
        default:
            return false
        }
    }

    func isValidAuthZStateToStart(_ authZState: AuthorizationState) -> Bool {
        switch authZState {
        case .configured, .sessionEstablished, .error:
            return true
        default:
            return false
        }
    }

    private func getFederatedResult(_ result: AmplifyCredentials)
    throws -> FederateToIdentityPoolResult {

        switch result {
        case .identityPoolWithFederation(_, let identityId, let awsCredentials):
            let federatedResult = FederateToIdentityPoolResult(
                credentials: awsCredentials,
                identityId: identityId)
            return federatedResult
        default:
            throw AuthError.unknown("Unable to parse credentials to expected output", nil)
        }
    }

}
