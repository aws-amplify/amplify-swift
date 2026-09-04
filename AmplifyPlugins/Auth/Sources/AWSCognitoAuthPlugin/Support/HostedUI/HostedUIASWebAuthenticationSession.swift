//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
#if os(iOS) || os(macOS) || os(visionOS)
@preconcurrency import AuthenticationServices
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class HostedUIASWebAuthenticationSession: NSObject, HostedUISessionBehavior {

    weak var webPresentation: AuthUIPresentationAnchor?

    func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: AuthUIPresentationAnchor?
    ) async throws -> [URLQueryItem] {

    #if os(iOS) || os(macOS) || os(visionOS)
        webPresentation = presentationAnchor

        return try await withCheckedThrowingContinuation { [weak self]
            (continuation: CheckedContinuation<[URLQueryItem], Error>) in
            guard let self else { return }

            let aswebAuthenticationSession = createAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme,
                completionHandler: { [weak self] url, error in
                    guard let self else { return }
                    if let url {
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
                        } else {
                            return continuation.resume(
                                returning: queryItems)
                        }
                    } else if let error {
                        return continuation.resume(
                            throwing: convertHostedUIError(error))
                    } else {
                        return continuation.resume(
                            throwing: HostedUIError.unknown)
                    }
                }
            )
            aswebAuthenticationSession.presentationContextProvider = self
            aswebAuthenticationSession.prefersEphemeralWebBrowserSession = inPrivate

            DispatchQueue.main.async {
                var canStart = true
                if #available(macOS 12.0, iOS 13.4, *) {
                    canStart = aswebAuthenticationSession.canStart
                }
                if canStart {
                    aswebAuthenticationSession.start()
                } else {
                    continuation.resume( throwing: HostedUIError.unableToStartASWebAuthenticationSession)
                }
            }
        }

    #else
        throw HostedUIError.serviceMessage("HostedUI is only available in iOS, macOS and visionOS")
    #endif
    }

#if os(iOS) || os(macOS) || os(visionOS)
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

#if os(iOS) || os(macOS) || os(visionOS)
extension HostedUIASWebAuthenticationSession: ASWebAuthenticationPresentationContextProviding {

    @MainActor
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let webPresentation {
            return webPresentation
        }
        // No anchor was provided. An empty `ASPresentationAnchor()` is a window
        // with no window scene, which iOS's scene-based UI never displays, so the
        // web UI would present off-screen and never load. Fall back to the app's
        // active key window instead.
        #if canImport(UIKit)
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let foregroundScenes = windowScenes.filter { $0.activationState == .foregroundActive }
        // A backgrounded scene's window is also never displayed, and the app may
        // have no window flagged as key while a presentation is in flight, so
        // prefer a foreground scene and fall back to any window it owns.
        let windows = (foregroundScenes.isEmpty ? windowScenes : foregroundScenes)
            .flatMap { $0.windows }
        return windows.first { $0.isKeyWindow } ?? windows.first ?? ASPresentationAnchor()
        #elseif canImport(AppKit)
        return NSApplication.shared.keyWindow
            ?? NSApplication.shared.windows.first
            ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}
#endif
