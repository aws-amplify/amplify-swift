//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

import ClientRuntime
import AWSCognitoIdentityProvider

typealias ConfigureOperation = AmplifyOperation<
    AuthConfigureRequest,
    Void,
    AuthError>

class AuthConfigureOperation: ConfigureOperation {

    let authConfiguration: AuthConfiguration
    let authStateMachine: AuthStateMachine
    let credentialStoreStateMachine: CredentialStoreStateMachine

    var authToken: AuthStateMachine.StateChangeListenerToken?
    var credentialStoreToken: CredentialStoreStateMachine.StateChangeListenerToken?

    init(request: AuthConfigureRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine) {

        self.authConfiguration = request.authConfiguration
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        super.init(categoryType: .auth,
                   eventName: "InternalConfigureAuth",
                   request: request)
    }

    deinit {
        authToken = nil
        credentialStoreToken = nil
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        sendConfigureAuthEvent()
    }

    func sendConfigureAuthEvent() {
        authToken = authStateMachine.listen({ [weak self] state in
            switch state {
            case .configured:
                self?.finish()
            default: break //TODO: Add any error handling if required.
            }
        }, onSubscribe: {[weak self] in
            guard let self = self else {
                return
            }

            let event = AuthEvent(eventType: .configureAuth(self.authConfiguration))
            self.authStateMachine.send(event)
        })
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
