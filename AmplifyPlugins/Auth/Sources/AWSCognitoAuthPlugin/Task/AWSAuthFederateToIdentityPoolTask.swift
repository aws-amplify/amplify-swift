//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthFederateToIdentityPoolTask: AmplifyAuthTask where Request == AuthFederateToIdentityPoolRequest,
                                                                        Success == FederateToIdentityPoolResult,
                                                                        Failure == AuthError {}

public extension HubPayload.EventName.Auth {
    /// eventName for HubPayloads emitted by this operation
    static let federateToIdentityPoolAPI = "Auth.federatedToIdentityPool"
}

public class AWSAuthFederateToIdentityPoolTask: AuthFederateToIdentityPoolTask {

    private let request: AuthFederateToIdentityPoolRequest
    private let authStateMachine: AuthStateMachine
    private var stateMachineToken: AuthStateMachineToken?
    
    public var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.federateToIdentityPoolAPI
    }

    init(_ request: AuthFederateToIdentityPoolRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
    }

    public func execute() async throws -> FederateToIdentityPoolResult {
        do {
            let state = await getCurrentState()
            guard case .configured(let authNState, let authZState) = state  else {
                throw AuthError.invalidState("Federation could not be completed.", AuthPluginErrorConstants.invalidStateError, nil)
            }

            if isValidAuthNStateToStart(authNState) && isValidAuthZStateToStart(authZState) {
                // Clear previous federation before beginning a new one
                if case .federatedToIdentityPool = authNState {
                    try await clearPreviousFederation()
                }
                let federatedResult = try await startFederatingToIdentityPool()
                cancelToken()
                return federatedResult
            } else {
                throw AuthError.invalidState("Federation could not be completed.", AuthPluginErrorConstants.invalidStateError, nil)
            }
        } catch {
            cancelToken()
            throw error
        }
    }

    private func getCurrentState() async -> AuthState {
        await withCheckedContinuation { (continuation: CheckedContinuation<AuthState, Never>) in
            authStateMachine.getCurrentState { state in
                continuation.resume(returning: state)
            }
        }
    }

    func clearPreviousFederation() async throws {
        let clearFederationHelper = ClearFederationOperationHelper()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
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

    func startFederatingToIdentityPool() async throws -> FederateToIdentityPoolResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FederateToIdentityPoolResult, Error>) in
            stateMachineToken = authStateMachine.listen { [weak self] state in
                guard  case .configured(let authNState, let authZState) = state else {
                    return
                }

                switch (authNState, authZState) {
                case (.federatedToIdentityPool, .sessionEstablished(let credentials)):
                    self?.getFederatedResult(credentials, continuation)
                case (.error(_), .error(let authZError)):
                    continuation.resume(throwing: authZError.authError)
                default:
                    break
                }

            } onSubscribe: { [weak self] in
                self?.sendStartFederatingToIdentityPoolEvent()
            }
        }
    }

    func sendStartFederatingToIdentityPoolEvent() {
        let federatedToken = FederatedToken(token: request.token, provider: request.provider)
        let identityId = request.options.developerProvidedIdentityID
        let event = AuthorizationEvent.init( eventType: .startFederationToIdentityPool(federatedToken, identityId))
        authStateMachine.send(event)
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

    private func getFederatedResult(_ result: AmplifyCredentials, _ continuation: CheckedContinuation<FederateToIdentityPoolResult, Error>) {
        switch result {
        case .identityPoolWithFederation(_, let identityId, let awsCredentials):
            let federatedResult = FederateToIdentityPoolResult(
                credentials: awsCredentials,
                identityId: identityId)
            continuation.resume(returning: federatedResult)
        default:
            continuation.resume(throwing: AuthError.unknown("Unable to parse credentials to expected output", nil))
        }
    }
    
    private func cancelToken() {
        if let token = stateMachineToken {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
