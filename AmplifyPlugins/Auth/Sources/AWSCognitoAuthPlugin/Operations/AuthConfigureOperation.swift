//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

import AWSCognitoIdentityProvider
import ClientRuntime

typealias ConfigureOperation = AmplifyOperation<
    AuthConfigureRequest,
    Void,
    AuthError
>

class AuthConfigureOperation: ConfigureOperation, @unchecked Sendable {

    let authConfiguration: AuthConfiguration
    let authStateMachine: AuthStateMachine
    let credentialStoreStateMachine: CredentialStoreStateMachine

    init(
        request: AuthConfigureRequest,
        authStateMachine: AuthStateMachine,
        credentialStoreStateMachine: CredentialStoreStateMachine
    ) {

        self.authConfiguration = request.authConfiguration
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        super.init(
            categoryType: .auth,
            eventName: "InternalConfigureAuth",
            request: request
        )
    }

    override func main() {
        if isCancelled {
            finish()
            dispatch(result: .failure(AuthError.configuration(
                "Configuration operation was cancelled",
                "", nil
            )))
            return
        }

        sendConfigureAuthEvent()
    }

    func sendConfigureAuthEvent() {
        Task {
            let event = AuthEvent(eventType: .configureAuth(self.authConfiguration))
            await self.authStateMachine.send(event)
            let stateSequences = await authStateMachine.listen()
            for await state in stateSequences {
                if case .configured = state {
                    finish()
                    dispatch(result: .success(()))
                    break
                }
            }
        }

    }
}

struct AuthConfigureRequest: AmplifyOperationRequest {

    let authConfiguration: AuthConfiguration

    var options: Options

    init(authConfiguration: AuthConfiguration, options: Options = Options()) {
        self.authConfiguration = authConfiguration
        self.options = options
    }
}

extension AuthConfigureRequest {

    struct Options {}
}
