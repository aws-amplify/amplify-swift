//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import ClientRuntime
import AWSCognitoIdentityProvider

class SetUpTOTPTask: AuthSetUpTOTPTask, DefaultLogger {

    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: SetUpTOTPRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.setUpTOTPAPI
    }

    init(_ request: SetUpTOTPRequest,
         authStateMachine: AuthStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> TOTPSetupDetails {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            return try await setUpTOTP(with: accessToken)
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    func setUpTOTP(with accessToken: String) async throws -> TOTPSetupDetails {
        let userPoolService = try userPoolFactory()
        let input = AssociateSoftwareTokenInput(accessToken: accessToken)
        let result = try await userPoolService.associateSoftwareToken(input: input)

        guard let secretCode = result.secretCode else {
            throw AuthError.service("Secret code cannot be retrieved", "")
        }

        // Get the current user for passing in the result, so that TOTP URI could constructed
        let authUser: AuthUser

        let currentState = await authStateMachine.currentState
        if case .configured(let authNState, _) = currentState,
           case .signedIn(let signInData) = authNState {
            authUser = AWSAuthUser(username: signInData.username, userId: signInData.userId)
        } else {
            throw AuthError.invalidState(
                "Auth State not in a valid state for the user",
                AuthPluginErrorConstants.invalidStateError,
                nil)
        }
        return .init(secretCode: secretCode,
                     username: authUser.username)

    }
}
