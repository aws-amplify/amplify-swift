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
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    let eventName: HubPayloadEventName

    init(_ request: AuthWebUISignInRequest,
         authConfiguration: AuthConfiguration,
         authStateMachine: AuthStateMachine,
         eventName: String
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.helper = HostedUISignInHelper(request: request,
                                           authstateMachine: authStateMachine,
                                           configuration: authConfiguration)
        self.eventName = eventName
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthSignInResult {

        do {
            await taskHelper.didStateMachineConfigured()
            let result = try await helper.initiateSignIn()
            return result
        } catch let autherror as AuthErrorConvertible {
            throw autherror.authError
        } catch let autherror as AuthError {
            throw autherror
        } catch let error {
            let error = AuthError.unknown("Not able to signIn to the webUI", error)
            throw error
        }
    }
}
