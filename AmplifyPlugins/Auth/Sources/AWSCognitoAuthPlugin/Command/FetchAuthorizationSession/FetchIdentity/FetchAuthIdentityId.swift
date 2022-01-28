//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import Foundation

struct FetchAuthIdentityId: Command {

    let identifier = "FetchAuthIdentityId"

    let cognitoSession: AWSAuthCognitoSession

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment)
    {
        
        guard let authZEnvironment = environment as? AuthorizationEnvironment,
              let client = try? authZEnvironment.cognitoIdentityFactory() else {
                  let authZError = AuthorizationError.configuration(message: AuthPluginErrorConstants.configurationError)
                  let event = FetchIdentityEvent(eventType: .throwError(authZError))
                  dispatcher.send(event)
                  
                  let updatedSession = cognitoSession.copySessionByUpdating(
                    identityIdResult: .failure(authZError.authError))
                  let fetchAwsCredentialsEvent = FetchAuthSessionEvent(
                    eventType: .fetchAWSCredentials(updatedSession))
                  dispatcher.send(fetchAwsCredentialsEvent)
                  return
        }
        
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        var loginsMap: [String: String] = [:]
        if case let .success(cognitoUserPoolTokens) = cognitoSession.cognitoTokensResult,
           let userpoolEnvironment = environment as? UserPoolEnvironment {
            
            let identityProviderName = userpoolEnvironment.userPoolConfiguration.getIdentityProviderName()
            loginsMap[identityProviderName] = cognitoUserPoolTokens.idToken
        }
        
        let getIdInput = GetIdInput(identityPoolId: authZEnvironment.identityPoolConfiguration.poolId,
                                    logins: loginsMap)
        client.getId(input: getIdInput) { result in
            switch result {
            case .success(let response):
                guard let identityId = response.identityId else {
                    let authZError = AuthorizationError.invalidIdentityId(
                      message: "IdentityId is invalid.")
                    let event = FetchIdentityEvent(eventType: .throwError(authZError))
                    dispatcher.send(event)
                    
                    let updateCognitoSession = cognitoSession.copySessionByUpdating(
                        identityIdResult: .failure(authZError.authError))
                    // Move to fetching the AWS Credentials
                    let fetchAwsCredentialsEvent = FetchAuthSessionEvent(
                        eventType: .fetchAWSCredentials(updateCognitoSession))
                    dispatcher.send(fetchAwsCredentialsEvent)
                    
                    timer.stop("### sending event \(fetchAwsCredentialsEvent.type)")
                    return
                }
                
                let updateCognitoSession = cognitoSession.copySessionByUpdating(
                    identityIdResult: .success(identityId))
                
                let fetchIdentityEvent = FetchIdentityEvent(eventType: .fetched)
                timer.note("### sending event \(fetchIdentityEvent.type)")
                dispatcher.send(fetchIdentityEvent)
                
                let fetchAwsCredentialsEvent = FetchAuthSessionEvent(
                    eventType: .fetchAWSCredentials(updateCognitoSession))
                timer.stop("### sending event \(fetchAwsCredentialsEvent.type)")
                dispatcher.send(fetchAwsCredentialsEvent)
                
            case .failure(let error):
                let authError = AuthorizationError.service(error: error)
                let event = FetchIdentityEvent(eventType: .throwError(authError))
                dispatcher.send(event)
                
                let updateCognitoSession = cognitoSession.copySessionByUpdating(
                    identityIdResult: .failure(error.authError))
                let fetchAwsCredentialsEvent = FetchAuthSessionEvent(
                    eventType: .fetchAWSCredentials(updateCognitoSession))
                timer.stop("### sending event \(fetchAwsCredentialsEvent.type)")
                dispatcher.send(fetchAwsCredentialsEvent)
            }
        }
    }
}

extension FetchAuthIdentityId: DefaultLogger { }

extension FetchAuthIdentityId: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchAuthIdentityId: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
