//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
#if os(iOS) || os(macOS)
import AuthenticationServices
#endif

class HostedUIASWebAuthenticationSession: NSObject, HostedUISessionBehavior {

    weak var webPresentation: AuthUIPresentationAnchor?

    func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: AuthUIPresentationAnchor?) async throws -> [URLQueryItem] {

    #if os(iOS) || os(macOS)
        self.webPresentation = presentationAnchor

        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[URLQueryItem], Error>) in

            let aswebAuthenticationSession = createAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme,
                completionHandler: { url, error in

                    if let url = url {
                        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                        let queryItems = urlComponents?.queryItems ?? []

                        // Validate if query items contains an error
                        if let error = queryItems.first(where: { $0.name == "error" })?.value {
                            let errorDescription = queryItems.first(
                                where: { $0.name == "error_description" }
                            )?.value?.trim() ?? ""
                            let message = "\(error) \(errorDescription)"
                            return continuation.resume(
                                throwing: HostedUIError.serviceMessage(message))
                        }
                        return continuation.resume(
                            returning: queryItems)
                    } else if let error = error {
                        return continuation.resume(
                            throwing: self.convertHostedUIError(error))
                    } else {
                        return continuation.resume(
                            throwing: HostedUIError.unknown)
                    }
                })
            aswebAuthenticationSession.presentationContextProvider = self
            aswebAuthenticationSession.prefersEphemeralWebBrowserSession = inPrivate

            DispatchQueue.main.async {
                aswebAuthenticationSession.start()
            }
        }

    #else
        throw HostedUIError.serviceMessage("HostedUI is only available in iOS and macOS")
    #endif
    }

#if os(iOS) || os(macOS)
    var authenticationSessionFactory = ASWebAuthenticationSession.init(url:callbackURLScheme:completionHandler:)
    
    private func createAuthenticationSession(
        url: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) -> ASWebAuthenticationSession {
        return authenticationSessionFactory(url, callbackURLScheme, completionHandler)
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
#endif
}

#if os(iOS) || os(macOS)
extension HostedUIASWebAuthenticationSession: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return webPresentation ?? ASPresentationAnchor()
    }
}
#endif
