//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

struct HostedUIRequestHelper {

    static func createSignInURL(state: String,
                                proofKey: String,
                                userContextData: String?,
                                configuration: HostedUIConfigurationData,
                                options: HostedUIOptions) throws -> URL {

        guard let proofData = proofKey.data(using: .ascii) else {
            throw HostedUIError.proofCalculation
        }
        let hash = SHA256.hash(data: proofData)
        let hashData = Data([UInt8](hash))
        let codeChallenge = urlSafeBase64(hashData.base64EncodedString())
        let normalizedScope = options
            .scopes
            .sorted()
            .joined(separator: " ")

        let signInURI = configuration.oauth
            .signInRedirectURI
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        var components = URLComponents()
        components.scheme = "https"
        components.path = "/oauth2/authorize"
        components.host = configuration.oauth.domain
        components.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "client_id", value: configuration.clientId),
            .init(name: "state", value: state),
            .init(name: "redirect_uri", value: signInURI),
            .init(name: "scope", value: normalizedScope),
            .init(name: "code_challenge", value: codeChallenge)
        ]

        if let userContextData = userContextData {
            components.queryItems?.append(
                .init(name: "userContextData", value: userContextData))
        }
        if let idpIdentifier = options.providerInfo.idpIdentifier {
            components.queryItems?.append(
                .init(name: "idp_identifier", value: idpIdentifier))
        } else if let authProvider = options.providerInfo.authProvider {
            components.queryItems?.append(
                .init(name: "identity_provider", value: authProvider.userPoolProviderName))
        }

        guard let url = components.url else {
            throw HostedUIError.signInURI
        }
        return url
    }

    static func createSignOutURL(configuration: HostedUIConfigurationData) throws -> URL {
        let signOutURI = configuration.oauth
            .signOutRedirectURI
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        var components = URLComponents()
        components.scheme = "https"
        components.path = "/logout"
        components.host = configuration.oauth.domain
        components.queryItems = [
            .init(name: "client_id", value: configuration.clientId),
            .init(name: "logout_uri", value: signOutURI)
        ]

        guard let logoutURL = components.url else {
            throw HostedUIError.signOutURI
        }
        return logoutURL
    }

    static func createTokenRequest(configuration: HostedUIConfigurationData,
                                   result: HostedUIResult) throws -> URLRequest {

        guard let signInRedirectURI = configuration.oauth
            .signInRedirectURI
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw HostedUIError.tokenURI
        }

        var components = URLComponents()
        components.scheme = "https"
        components.path = "/oauth2/token"
        components.host = configuration.oauth.domain

        guard let url = components.url else {
            throw HostedUIError.tokenURI
        }

        var queryComponents = URLComponents()
        queryComponents.queryItems = [
            .init(name: "grant_type", value: "authorization_code"),
            .init(name: "client_id", value: configuration.clientId),
            .init(name: "code", value: result.code),
            .init(name: "redirect_uri", value: signInRedirectURI),
            .init(name: "code_verifier", value: result.codeVerifier)]

        guard let body = queryComponents.query else {
            throw HostedUIError.tokenURI
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body.data(using: .utf8)
        urlRequest.addHeaders(using: configuration)
        return urlRequest
    }

    static func createRefreshTokenRequest(
        refreshToken: String,
        configuration: HostedUIConfigurationData) throws -> URLRequest {

            var components = URLComponents()
            components.scheme = "https"
            components.path = "/oauth2/token"
            components.host = configuration.oauth.domain

            guard let url = components.url else {
                throw HostedUIError.tokenURI
            }

            var queryComponents = URLComponents()
            queryComponents.queryItems = [
                .init(name: "grant_type", value: "refresh_token"),
                .init(name: "refresh_token", value: refreshToken),
                .init(name: "client_id", value: configuration.clientId)]

            guard let body = queryComponents.query else {
                throw HostedUIError.tokenURI
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = body.data(using: .utf8)
            urlRequest.addHeaders(using: configuration)
            return urlRequest
        }

    static func urlSafeBase64(_ content: String) -> String {
        return content.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension URLRequest {
    mutating func addHeaders(using configuration: HostedUIConfigurationData) {
        guard let clientSecret = configuration.clientSecret,
              let value = "\(configuration.clientId):\(clientSecret)".data(using: .utf8) else {
            return
        }

        setValue("Basic \(value.base64EncodedString())", forHTTPHeaderField: "Authorization")
    }
}
