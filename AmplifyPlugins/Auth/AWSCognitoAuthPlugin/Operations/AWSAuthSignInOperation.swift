//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthSignInOperation: AmplifyOperation<
    AuthSignInRequest,
    AuthSignInResult,
    AuthError
>, AuthSignInOperation {

    let authenticationProvider: AuthenticationProviderBehavior
    let configuration: JSONValue

    init(_ request: AuthSignInRequest,
         configuration: JSONValue,
         authenticationProvider: AuthenticationProviderBehavior,
         resultListener: ResultListener?) {

        self.authenticationProvider = authenticationProvider
        self.configuration = configuration
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signInAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        if let validationError = request.hasError() {
            dispatch(validationError)
            finish()
            return
        }

        // Get the authflowType and apply that to the existing request.
        guard let authFlowType = authFlowType(from: request) else {
            let error = AuthError.configuration(
                "Not a valid auth flow type",
                "AWSCognitoAuthPlugin currently supports only SRP and Custom auth")
            dispatch(error)
            finish()
            return
        }

        let currentOptions = request.options.pluginOptions as? AWSAuthSignInOptions
        let options = AWSAuthSignInOptions(validationData: (currentOptions)?.validationData,
                                           metadata: (currentOptions)?.metadata,
                                           authFlowType: authFlowType)

        let signInrequest = AuthSignInRequest(username: request.username,
                                              password: request.password,
                                              options: .init(pluginOptions: options))
        authenticationProvider.signIn(request: signInrequest) {[weak self]  result in
            guard let self = self else { return }

            defer {
                self.finish()
            }

            if self.isCancelled {
                return
            }

            switch result {
            case .failure(let error):
                self.dispatch(error)
            case .success(let signInResult):
                self.dispatch(signInResult)
            }
        }
    }

    private func dispatch(_ result: AuthSignInResult) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }

    // Determine the auth flow type to use for the signIn flow.
    //
    // First we check if authflow type is passed as a parameter in the signIn api. If not we
    // determine the authflow type from the configuration. If there is no configured authflowType
    // we will take srp as the default type.
    private func authFlowType(from request: AuthSignInRequest) -> AuthFlowType? {

        if let authType = (request.options.pluginOptions as? AWSAuthSignInOptions)?.authFlowType,
           authType != .unknown {
            return authType
        }

        let authTypeKeyPath = "Auth.Default.authenticationFlowType"
        guard case .string(let authTypeString) = configuration.value(at: authTypeKeyPath) else {
            return .userSRP
        }

        switch authTypeString {
        case "CUSTOM_AUTH": return .custom
        case "USER_SRP_AUTH": return .userSRP
        case "USER_PASSWORD_AUTH": return .userPasswordAuth
        default:
            return nil
        }

    }
}
