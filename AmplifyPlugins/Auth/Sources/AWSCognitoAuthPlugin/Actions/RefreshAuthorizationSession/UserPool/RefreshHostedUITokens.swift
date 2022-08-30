//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct RefreshHostedUITokens: Action {

    let identifier = "RefreshHostedUITokens"

    let existingSignedIndata: SignedInData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        Task {
            await refresh(
                withDispatcher: dispatcher,
                environment: environment
            )
        }
    }

    func refresh(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        do {

            logVerbose("\(#fileID) Starting execution", environment: environment)
            guard let environment = environment as? AuthEnvironment,
            let hostedUIEnvironment = environment.hostedUIEnvironment else {
                let event = RefreshSessionEvent.init(eventType: .throwError(.noUserPool))
                dispatcher.send(event)
                return
            }
            let configuration = environment.userPoolConfiguration
            let existingTokens = existingSignedIndata.cognitoUserPoolTokens

            let request = try HostedUIRequestHelper.createRefreshTokenRequest(
                refreshToken: existingTokens.refreshToken,
                configuration: hostedUIEnvironment.configuration)

            let task = hostedUIEnvironment.urlSessionFactory().dataTask(with: request) {
                data, _, error in

                if let error = error {
                    let event = RefreshSessionEvent(eventType: .throwError(.service(error)))
                    logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    dispatcher.send(event)
                } else if let data = data {
                    handleData(data,
                               dispatcher: dispatcher,
                               environment: environment,
                               configuration:  configuration)
                } else {
                    let event = RefreshSessionEvent(eventType: .throwError(.invalidTokens))
                    logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    dispatcher.send(event)
                }
            }
            task.resume()

        } catch {
            let event = RefreshSessionEvent(eventType: .throwError(.service(error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }

        logVerbose("\(#fileID) Refresh hostedUI token complete", environment: environment)

    }

    func handleData(_ data: Data,
                    dispatcher: EventDispatcher,
                    environment: Environment,
                    configuration: UserPoolConfigurationData) {
        do {
            guard let json = try JSONSerialization.jsonObject(
                with: data,
                options: []) as? [String: Any] else {
                logVerbose("\(#fileID) Parsing failed", environment: environment)
                throw FetchSessionError.invalidTokens
            }

            if let errorString = json["error"] as? String {
                let description = json["error_description"] as? String ?? ""
                let error = HostedUIError.serviceMessage("\(errorString) \(description)")
                throw FetchSessionError.service(error)

            } else if let idToken = json["id_token"] as? String,
                      let accessToken = json["access_token"] as? String,
                      let expiresIn = json["expires_in"] as? Int {
                let userPoolTokens = AWSCognitoUserPoolTokens(
                    idToken: idToken,
                    accessToken: accessToken,
                    refreshToken: existingSignedIndata.cognitoUserPoolTokens.refreshToken,
                    expiresIn: expiresIn)
                let signedInData = SignedInData(
                    signedInDate: existingSignedIndata.signedInDate,
                    signInMethod: existingSignedIndata.signInMethod,
                    cognitoUserPoolTokens: userPoolTokens)

                let event: RefreshSessionEvent

                if ((environment as? AuthEnvironment)?.identityPoolConfigData) != nil {
                    let provider = CognitoUserPoolLoginsMap(
                        idToken: idToken,
                        region: configuration.region,
                        poolId: configuration.poolId)
                    event = .init(eventType: .refreshIdentityInfo(signedInData, provider))
                } else {
                    event = .init(eventType: .refreshedCognitoUserPool(signedInData))
                }
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                dispatcher.send(event)

            } else {
                logVerbose("\(#fileID) Could not retrieve tokens", environment: environment)
                throw FetchSessionError.invalidTokens
            }
        } catch let sessionError as FetchSessionError {
            let event = RefreshSessionEvent(eventType: .throwError(sessionError))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch {
            let event = RefreshSessionEvent(eventType: .throwError(.service(error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }
    }
}

extension RefreshHostedUITokens: DefaultLogger { }

extension RefreshHostedUITokens: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "existingSignedInData": existingSignedIndata
        ]
    }
}

extension RefreshHostedUITokens: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
