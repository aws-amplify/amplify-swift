//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import Foundation
import Amplify

struct FetchAuthAWSCredentials: Action {
    
    let identifier = "FetchAuthAwsCredentials"
    
    let cognitoSession: AWSAuthCognitoSession
    
    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment)
    {
        guard let authZEnvironment = environment as? AuthorizationEnvironment,
              let client = try? authZEnvironment.cognitoIdentityFactory() else {
                  
                  let authZError = AuthorizationError.configuration(message: AuthPluginErrorConstants.configurationError)
                  let event = FetchAWSCredentialEvent(eventType: .throwError(authZError))
                  dispatcher.send(event)
                  
                  let updatedSession = cognitoSession.copySessionByUpdating(
                    awsCredentialsResult: .failure(authZError.authError))
                  let fetchedAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(updatedSession))
                  dispatcher.send(fetchedAuthSessionEvent)
                  
                  return
              }
        
        guard case let .success(identityId) = cognitoSession.identityIdResult else {
            
            // Ideally the unknown error would never happen
            var authError = AuthError.unknown("Unknown Error", nil)
            if case let .failure(error) = cognitoSession.identityIdResult {
                authError = error
            }
            
            let authZError = AuthorizationError.service(error: authError)
            let event = FetchAWSCredentialEvent(eventType: .throwError(authZError))
            dispatcher.send(event)
            
            let updatedSession = cognitoSession.copySessionByUpdating(awsCredentialsResult: .failure(authError))
            let fetchedAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(updatedSession))
            dispatcher.send(fetchedAuthSessionEvent)
            
            return
        }
        
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        var loginsMap: [String: String] = [:]
        if case let .success(cognitoUserPoolTokens) = cognitoSession.cognitoTokensResult,
           let userPoolEnvironment = environment as? UserPoolEnvironment {
            
            let identityProviderName = userPoolEnvironment.userPoolConfiguration.getIdentityProviderName()
            loginsMap[identityProviderName] = cognitoUserPoolTokens.idToken
        }
        
        let getCredentialsInput = GetCredentialsForIdentityInput(identityId: identityId,
                                                                 logins: loginsMap)
        client.getCredentialsForIdentity(input: getCredentialsInput) { result in
            switch result {
            case .success(let response):
                guard let identityId = response.identityId else {
                    let authZError = AuthorizationError.invalidIdentityId(
                        message: "IdentityId is invalid.")
                    let event = FetchAWSCredentialEvent(eventType: .throwError(authZError))
                    dispatcher.send(event)
                    
                    let updatedSession = cognitoSession.copySessionByUpdating(
                        awsCredentialsResult: .failure(authZError.authError))
                    let fetchedAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(updatedSession))
                    dispatcher.send(fetchedAuthSessionEvent)
                    
                    timer.stop("### sending \(fetchedAuthSessionEvent.type)")
                    return
                }
                guard let awsCredentials = response.credentials,
                      let accessKey = awsCredentials.accessKeyId,
                      let secretKey = awsCredentials.secretKey,
                      let sessionKey = awsCredentials.sessionToken,
                      let expiration = awsCredentials.expiration else {
                          let authZError = AuthorizationError.invalidAWSCredentials(
                            message: "AWSCredentials are invalid.")
                          let event = FetchAWSCredentialEvent(eventType: .throwError(authZError))
                          dispatcher.send(event)
                          
                          let updatedSession = cognitoSession.copySessionByUpdating(
                            awsCredentialsResult: .failure(authZError.authError))
                          let fetchedAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(updatedSession))
                          dispatcher.send(fetchedAuthSessionEvent)
                          
                          timer.stop("### sending \(fetchedAuthSessionEvent.type)")
                          return
                      }
                let awsCognitoCredentials = AuthAWSCognitoCredentials(
                    accessKey: accessKey,
                    secretKey: secretKey,
                    sessionKey: sessionKey,
                    expiration: expiration
                )
                
                let updatedSession = cognitoSession.copySessionByUpdating(
                    identityIdResult: .success(identityId),
                    awsCredentialsResult: .success(awsCognitoCredentials)
                )
                
                let fetchedAWSCredentialEvent = FetchAWSCredentialEvent(eventType: .fetched)
                timer.note("### sending \(fetchedAWSCredentialEvent.type)")
                dispatcher.send(fetchedAWSCredentialEvent)
                
                let fetchedAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(updatedSession))
                timer.stop("### sending \(fetchedAuthSessionEvent.type)")
                dispatcher.send(fetchedAuthSessionEvent)
                
            case .failure(let error):
                let authError = AuthorizationError.service(error: error)
                let event = FetchAWSCredentialEvent(eventType: .throwError(authError))
                dispatcher.send(event)
                
                let updatedSession = cognitoSession.copySessionByUpdating(
                  awsCredentialsResult: .failure(error.authError))
                let fetchedAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession(updatedSession))
                timer.stop("### sending \(fetchedAuthSessionEvent.type)")
                dispatcher.send(fetchedAuthSessionEvent)
            }
        }
        
    }
}

extension FetchAuthAWSCredentials: DefaultLogger { }

extension FetchAuthAWSCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchAuthAWSCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
