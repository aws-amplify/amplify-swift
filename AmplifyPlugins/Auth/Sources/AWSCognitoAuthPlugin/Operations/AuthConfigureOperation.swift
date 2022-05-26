//
//  File.swift
//  
//
//  Created by Roy, Jithin on 5/25/22.
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

        /// Auth needs the Credential Store to be configured first.
        sendConfigureCredentialEvent() { result in
            self.credentialStoreToken = nil
            do {
                /// If Credential store is successfully configured send event to configure auth statemachine.
                /// Auth state change listener should finish this operation after that.
                let credentials = try result.get()
                self.sendConfigureAuthEvent(with: credentials)
            } catch {
                // TODO: Fix failure, should we move auth state to an error state?
                self.finish()
            }
        }
    }

    func sendConfigureCredentialEvent(
        completion: @escaping (Result<AmplifyCredentials?, Error>) -> Void) {
        credentialStoreToken = credentialStoreStateMachine.listen {

            switch $0 {
            case .success(let storedCredentials):
                completion(.success(storedCredentials))

            case .error(let credentialStoreError):

                guard case .itemNotFound = credentialStoreError else {
                    let error = AuthError.service(
                        "An exception occurred when configuring credential store",
                        AmplifyErrorMessages.reportBugToAWS(),
                        credentialStoreError)
                    completion(.failure(error))
                    return
                }

                completion(.success(nil))
            default:
                break
            }
        } onSubscribe: { [weak self] in
            let event = CredentialStoreEvent(eventType: .migrateLegacyCredentialStore)
            self?.credentialStoreStateMachine.send(event)
        }
    }

    func sendConfigureAuthEvent(with storedCredentials: AmplifyCredentials?) {
        authToken = authStateMachine.listen({ [weak self] state in
            switch state {
            case .configured(_, _):
                self?.finish()
            default: break
            }
        }, onSubscribe: {[weak self] in
            guard let self = self else {
                return
            }

            let event = AuthEvent(eventType: .configureAuth(self.authConfiguration, storedCredentials))
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
