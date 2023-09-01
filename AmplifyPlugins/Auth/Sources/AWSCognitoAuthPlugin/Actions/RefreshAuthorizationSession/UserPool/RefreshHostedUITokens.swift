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
                await dispatcher.send(event)
                return
            }
            let configuration = environment.userPoolConfiguration
            let existingTokens = existingSignedIndata.cognitoUserPoolTokens

            let request = try HostedUIRequestHelper.createRefreshTokenRequest(
                refreshToken: existingTokens.refreshToken,
                configuration: hostedUIEnvironment.configuration)

            let data = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Data, Error>) in
                let task = hostedUIEnvironment.urlSessionFactory().dataTask(with: request) {
                    data, _, error in
                    if let error = error {
                        continuation.resume(with: .failure(FetchSessionError.service(error)))
                    } else if let data = data {
                        continuation.resume(with: .success(data))
                    } else {
                        continuation.resume(with: .failure(FetchSessionError.invalidTokens))
                    }
                }
                task.resume()
            }
            let signedInData = try await handleData(data,
                                                    configuration: configuration)
            let event: RefreshSessionEvent

            if (environment.identityPoolConfigData) != nil {
                let provider = CognitoUserPoolLoginsMap(
                    idToken: signedInData.cognitoUserPoolTokens.idToken,
                    region: configuration.region,
                    poolId: configuration.poolId)
                event = .init(eventType: .refreshIdentityInfo(signedInData, provider))
            } else {
                event = .init(eventType: .refreshedCognitoUserPool(signedInData))
            }
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)

        } catch let fetchError as FetchSessionError {
            let event = RefreshSessionEvent(eventType: .throwError(fetchError))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch {
            let event = RefreshSessionEvent(eventType: .throwError(.service(error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }
        logVerbose("\(#fileID) Refresh hostedUI token complete", environment: environment)
    }

    func handleData(_ data: Data,
                    configuration: UserPoolConfigurationData) async throws -> SignedInData {
        guard let json = try JSONSerialization.jsonObject(
            with: data,
            options: []) as? [String: Any] else {
            throw FetchSessionError.invalidTokens
        }

        if let errorString = json["error"] as? String {
            let description = json["error_description"] as? String ?? ""
            let error = HostedUIError.serviceMessage("\(errorString) \(description)")
            throw FetchSessionError.service(error)

        } else if let idToken = json["id_token"] as? String,
                  let accessToken = json["access_token"] as? String {
            let userPoolTokens = AWSCognitoUserPoolTokens(
                idToken: idToken,
                accessToken: accessToken,
                refreshToken: existingSignedIndata.cognitoUserPoolTokens.refreshToken,
                expiresIn: json["expires_in"] as? Int)
            return SignedInData(
                signedInDate: existingSignedIndata.signedInDate,
                signInMethod: existingSignedIndata.signInMethod,
                cognitoUserPoolTokens: userPoolTokens)
        } else {
            throw FetchSessionError.invalidTokens
        }
    }
}

extension RefreshHostedUITokens: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }
    
    public var log: Logger {
        Self.log
    }
}

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
