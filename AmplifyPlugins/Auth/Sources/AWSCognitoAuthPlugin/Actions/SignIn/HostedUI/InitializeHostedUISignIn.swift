//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import CryptoKit

struct InitializeHostedUISignIn: Action {

    var identifier: String = "InitializeHostedUISignIn"

    let options: HostedUIOptions

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

        let state = UUID().uuidString.lowercased()
        let proofKey = generateRandom()
        let hash = SHA256.hash(data: proofKey)
        let hashData = Data([UInt8](hash))
        let codeChallenge = urlSafeBase64(hashData.base64EncodedString())
        let normalizedScope = options.scopes.sorted().joined(separator: " ")
        // TODO: Add ASF

        let signInURI = hostedUIConfig.oauth
            .signInRedirectURI
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        var components = URLComponents()
        components.scheme = "https"
        components.host = hostedUIConfig.oauth.domain
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge_method", value: "256"),
            URLQueryItem(name: "client_id", value: hostedUIConfig.clientId),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "redirect_uri", value: signInURI),
            URLQueryItem(name: "scope", value: normalizedScope),
            URLQueryItem(name: "code_challenge", value: codeChallenge),

        ]

        guard let url = components.url else {
            fatalError("''")
        }

        let signInData = HostedUISignInData(signInURL: url, state: state, codeChallenge: codeChallenge)
        let event = HostedUIEvent(eventType: .showHostedUI(signInData))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }

    private func generateRandom() -> Data {
        let byteSize = 32
        var randomBytes = [UInt8](repeating: 0, count: byteSize)
        let result = SecRandomCopyBytes(kSecRandomDefault, byteSize, &randomBytes)
        guard result == errSecSuccess else {
            fatalError("Error occured in generating random bytes")
        }
        return Data(randomBytes)
    }

    private func urlSafeBase64(_ content: String) -> String {
        return content.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension InitializeHostedUISignIn: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeHostedUISignIn: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
