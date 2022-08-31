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

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment,
              let hostedUIEnvironment = environment.hostedUIEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = AuthenticationEvent(eventType: .error(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
            return
        }

        let hostedUIConfig = hostedUIEnvironment.configuration
        do {
            let request = try HostedUIRequestHelper.createTokenRequest(
                configuration: hostedUIConfig,
                result: result)

            let data = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Data, Error>) in
                let task = hostedUIEnvironment.urlSessionFactory().dataTask(with: request) {
                    data, _, error in

                    if let error = error {
                        continuation.resume(with: .failure(SignInError.service(error: error)))
                    } else if let data = data {
                        continuation.resume(with: .success(data))
                    } else {
                        continuation.resume(with: .failure(SignInError.hostedUI(.tokenParsing)))
                    }
                }
                task.resume()
            }

            let signedInData = try await handleData(data)
            let event =  SignInEvent(eventType: .finalizeSignIn(signedInData))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)

        } catch let hostedUIError as HostedUIError {
            let signInError = SignInError.hostedUI(hostedUIError)
            let event = HostedUIEvent(eventType: .throwError(signInError))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch {
            let signInError = SignInError.service(error: error)
            let event = HostedUIEvent(eventType: .throwError(signInError))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }
    }

    func handleData(_ data: Data) async throws -> SignedInData {
        guard let json = try JSONSerialization.jsonObject(
            with: data,
            options: []) as? [String: Any] else {
            throw HostedUIError.tokenParsing
        }

        if let errorString = json["error"] as? String {
            let description = json["error_description"] as? String ?? ""
            throw HostedUIError.serviceMessage("\(errorString) \(description)")

        } else if let idToken = json["id_token"] as? String,
                  let accessToken = json["access_token"] as? String,
                  let refreshToken = json["refresh_token"] as? String,
                  let expiresIn = json["expires_in"] as? Int {
            let userPoolTokens = AWSCognitoUserPoolTokens(
                idToken: idToken,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn)
            let signedInData = SignedInData(
                signedInDate: Date(),
                signInMethod: .hostedUI(result.options),
                cognitoUserPoolTokens: userPoolTokens)
            return signedInData
        } else {
            throw HostedUIError.tokenParsing
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
