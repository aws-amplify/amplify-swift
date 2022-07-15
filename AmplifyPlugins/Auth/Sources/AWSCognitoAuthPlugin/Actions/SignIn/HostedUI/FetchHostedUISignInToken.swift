//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import CryptoKit

struct FetchHostedUISignInToken: Action {

    var identifier: String = "FetchHostedUISignInToken"

    let result: HostedUIResult

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIConfig = environment.userPoolConfiguration.hostedUIConfig else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = AuthenticationEvent(eventType: .error(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        guard let signInRedirectURI = hostedUIConfig.oauth
            .signInRedirectURI
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(.signInURI)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        var components = URLComponents()
        components.scheme = "https"
        components.path = "/oauth2/token"
        components.host = hostedUIConfig.oauth.domain

        guard let url = components.url else {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(.signInURI)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        var queryComponents = URLComponents()
        queryComponents.queryItems = [URLQueryItem(name: "grant_type", value: "authorization_code"),
                                      URLQueryItem(name: "client_id", value: hostedUIConfig.clientId),
                                      URLQueryItem(name: "code", value: result.code),
                                      URLQueryItem(name: "redirect_uri", value: signInRedirectURI),
                                      URLQueryItem(name: "code_verifier", value: result.codeVerifier)]

        guard let body = queryComponents.query else {
            let event = HostedUIEvent(eventType: .throwError(.hostedUI(.signInURI)))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: urlRequest) { data, urlResponse, error in

            if let error = error {
                let signInError = SignInError.service(error: error)
                let event = HostedUIEvent(eventType: .throwError(signInError))
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                dispatcher.send(event)
            }
            else if let data = data {
                handleData(data, dispatcher: dispatcher, environment: environment)
            } else {
                let signInError = SignInError.unknown(message: "Could not fetch Token: \(urlResponse.debugDescription)")
                let event = HostedUIEvent(eventType: .throwError(signInError))
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                dispatcher.send(event)
            }
        }
        task.resume()
    }

    func handleData(_ data: Data, dispatcher: EventDispatcher, environment: Environment) {
        do {

            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {

                if let errorString = json["error"] as? String {
                    let description = json["error_description"] as? String ?? ""
                    let hostedUIError = HostedUIError.serviceMessage("\(errorString) \(description)")
                    let event = HostedUIEvent(eventType: .throwError(.hostedUI(hostedUIError)))
                    logVerbose("\(#fileID) Sending event \(event)", environment: environment)
                    dispatcher.send(event)

                } else if let idToken = json["id_token"] as? String,
                          let accessToken = json["access_token"] as? String,
                          let refreshToken = json["refresh_token"] as? String,
                          let expiresIn = json["expires_in"] as? Int {
                    let userPoolTokens = AWSCognitoUserPoolTokens(idToken: idToken,
                                                                  accessToken: accessToken,
                                                                  refreshToken: refreshToken,
                                                                  expiresIn: expiresIn)
                    let user = try TokenParserHelper.getAuthUser(accessToken: accessToken)
                    let signedInData = SignedInData(userId: user.userId,
                                                    userName: user.username,
                                                    signedInDate: Date(),
                                                    signInMethod: .hostedUI(result.options),
                                                    cognitoUserPoolTokens: userPoolTokens)

                    let event =  SignInEvent(eventType: .finalizeSignIn(signedInData))
                    logVerbose("\(#fileID) Sending event \(event)", environment: environment)
                    dispatcher.send(event)

                } else {
                    let signInError = SignInError.unknown(message: "Could not fetch Token")
                    let event = HostedUIEvent(eventType: .throwError(signInError))
                    logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    dispatcher.send(event)
                }
            }
        } catch let signInError as SignInError {
            let event = HostedUIEvent(eventType: .throwError(signInError))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch {
            let signInError = SignInError.service(error: error)
            let event = HostedUIEvent(eventType: .throwError(signInError))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }
    }
}

extension FetchHostedUISignInToken: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "result": result.debugDescription
        ]
    }
}

extension FetchHostedUISignInToken: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
