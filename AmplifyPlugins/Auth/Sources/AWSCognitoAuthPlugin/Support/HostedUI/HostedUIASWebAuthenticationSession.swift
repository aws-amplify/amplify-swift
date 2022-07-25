//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AuthenticationServices

class HostedUIASWebAuthenticationSession: NSObject, HostedUISessionBehavior {

    weak var webPresentation: AuthUIPresentationAnchor? = nil

    func showHostedUI(url: URL,
                      callbackScheme: String,
                      inPrivate: Bool,
                      presentationAnchor: AuthUIPresentationAnchor?,
                      callback: @escaping (Result<[URLQueryItem], HostedUIError>) -> Void) {

        self.webPresentation = presentationAnchor
        let aswebAuthenticationSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme,
            completionHandler: { url, error in
                if let url = url {
                    let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let queryItems = urlComponents?.queryItems ?? []

                    if let error = queryItems.first(where: { $0.name == "error" })?.value {
                        callback(.failure(.serviceMessage(error)))
                        return
                    }
                    callback(.success(queryItems))
                } else if let error = error {
                    callback(.failure(self.convertHostedUIError(error)))

                } else {
                    callback(.failure(.unknown))
                }
            })
        aswebAuthenticationSession.presentationContextProvider = self
        aswebAuthenticationSession.prefersEphemeralWebBrowserSession = inPrivate

        DispatchQueue.main.async {
            aswebAuthenticationSession.start()
        }
    }

    private func convertHostedUIError(_ error: Error) -> HostedUIError {
        if let asWebAuthError = error as? ASWebAuthenticationSessionError {
            switch asWebAuthError.code {
            case .canceledLogin:
                return .cancelled
            case .presentationContextNotProvided:
                return .invalidContext
            case .presentationContextInvalid:
                return .invalidContext
            @unknown default:
                return .unknown
            }
        }
        return .unknown
    }
}

extension HostedUIASWebAuthenticationSession: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return webPresentation ?? ASPresentationAnchor()
    }
}
