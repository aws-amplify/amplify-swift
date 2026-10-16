//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if os(iOS) || os(macOS) || os(visionOS)
@preconcurrency import AuthenticationServices
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// - Note: `final` and `@unchecked Sendable` to satisfy `HostedUISessionBehavior`. The presentation
///   anchor and session factory are assigned before the session is shown.
package final class HostedUIASWebAuthenticationSession: NSObject, HostedUISessionBehavior, @unchecked Sendable {

    weak var webPresentation: EnginePresentationAnchor?

    package func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: EnginePresentationAnchor?
    ) async throws -> [URLQueryItem] {

    #if os(iOS) || os(macOS) || os(visionOS)
        webPresentation = presentationAnchor

        return try await withCheckedThrowingContinuation { [weak self]
            (continuation: CheckedContinuation<[URLQueryItem], Error>) in
            guard let self else { return }

            // Both the completion handler and a failed `start()` can end the flow, so the
            // continuation is resumed by whichever gets there first and never a second time.
            let resumeOnce = ResumeOnce()
            let cancellation = cancellation
            let flow = cancellation.mintFlow()
            let resume: @Sendable (Result<[URLQueryItem], Error>) -> Void = { [weak self] result in
                guard resumeOnce.claim() else { return }
                self?.inFlightSession.set(nil)
                cancellation.end(flow)
                continuation.resume(with: result)
            }
            // A `cancel()` that came first ends the flow before anything is created or shown.
            guard cancellation.begin(flow, resume: resume) else {
                return resume(.failure(HostedUIError.cancelled))
            }

            let aswebAuthenticationSession = createAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme,
                completionHandler: { [weak self] url, error in
                    guard let self else { return }
                    resume(result(ofCallback: url, error: error))
                }
            )
            aswebAuthenticationSession.presentationContextProvider = self
            aswebAuthenticationSession.prefersEphemeralWebBrowserSession = inPrivate

            DispatchQueue.main.async { [weak self] in
                // `cancel()` sets its flag before it queues its own main-queue work, so a flow cancelled
                // before this runs is never shown, and one cancelled after is found and dismissed there.
                guard !cancellation.isCancelled else {
                    return resume(.failure(HostedUIError.cancelled))
                }
                var canStart = true
                if #available(macOS 12.0, iOS 13.4, *) {
                    canStart = aswebAuthenticationSession.canStart
                }
                guard canStart else {
                    return resume(.failure(HostedUIError.unableToStartASWebAuthenticationSession))
                }
                // Retain the session for the duration of the flow; `resume` releases it.
                self?.inFlightSession.set(aswebAuthenticationSession)
                if !aswebAuthenticationSession.start() {
                    // `canStart` only predicts `start()`. When `start()` itself fails, the
                    // completion handler is not guaranteed to fire, so end the flow here.
                    resume(.failure(HostedUIError.unableToStartASWebAuthenticationSession))
                }
            }
        }

    #else
        throw HostedUIError.serviceMessage("HostedUI is only available in iOS, macOS and visionOS")
    #endif
    }

#if os(iOS) || os(macOS) || os(visionOS)
    /// Dismisses the browser and ends the flow in progress with `HostedUIError.cancelled`, whether or not
    /// the system then calls the session's completion handler. Returns at once: the dismissal runs on the
    /// main queue, never blocking the caller, which may be a cancellation handler on another actor.
    ///
    /// **Sticky.** Once cancelled, this presenter shows nothing again: a later `showHostedUI` throws
    /// `.cancelled` at once. That closes the race of a cancel arriving before the flow reaches the
    /// presenter. A presenter serves one flow (the plugin's environment makes one per flow, the client one
    /// per operation), so nothing is lost. Idempotent; a no-op after the flow has completed.
    package func cancel() {
        let pending = cancellation.cancel()
        // On the main queue, like the flow's `start()`: a session started before this runs is found and
        // dismissed, and a flow whose start has not run yet sees the flag and never starts.
        DispatchQueue.main.async { [weak self] in
            self?.inFlightSession.get()?.cancel()
            pending?(.failure(HostedUIError.cancelled))
        }
    }

    private let cancellation = PresenterCancellation()

    private let inFlightSession = AtomicValue<ASWebAuthenticationSession?>(initialValue: nil)

    /// The `ASWebAuthenticationSession` of the flow in progress, retained until the flow completes.
    var authenticationSession: ASWebAuthenticationSession? {
        inFlightSession.get()
    }

    var authenticationSessionFactory = ASWebAuthenticationSession.init(url:callbackURLScheme:completionHandler:)

    private func createAuthenticationSession(
        url: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) -> ASWebAuthenticationSession {
        return authenticationSessionFactory(url, callbackURLScheme, completionHandler)
    }

    /// What the session's completion handler ends the flow with: the callback URL's query items, the
    /// hosted UI's own `error` and `error_description` when the callback carries them, or the session's error.
    private func result(ofCallback url: URL?, error: Error?) -> Result<[URLQueryItem], Error> {
        if let url {
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = urlComponents?.queryItems ?? []

            // Validate if query items contains an error
            if let error = queryItems.first(where: { $0.name == "error" })?.value {
                let errorDescription = queryItems.first(
                    where: { $0.name == "error_description" }
                )?.value?.trim() ?? ""
                let message = "\(error) \(errorDescription)"
                return .failure(HostedUIError.serviceMessage(message))
            } else {
                return .success(queryItems)
            }
        } else if let error {
            return .failure(convertHostedUIError(error))
        } else {
            return .failure(HostedUIError.unknown)
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
#endif
}

#if os(iOS) || os(macOS) || os(visionOS)
/// Grants the right to resume a continuation to the first caller only.
///
/// - Note: `AtomicValue` is not used here because, inside this module, the name resolves to the
///   state machine's internal `AtomicValue`, which is not `Sendable` and so cannot be captured by
///   the `@Sendable` resume closure.
private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var claimed = false

    /// Returns `true` for the first call and `false` for every call after it.
    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !claimed else { return false }
        claimed = true
        return true
    }
}

/// Whether a presenter was cancelled, and the flow in progress to end if it is. Shared by `cancel()`
/// and the flow's `resume`, under one lock.
private final class PresenterCancellation: @unchecked Sendable {

    typealias Resume = @Sendable (Result<[URLQueryItem], Error>) -> Void

    private let lock = NSLock()
    private var cancelled = false
    private var nextFlow: UInt64 = 0
    private var pending: (flow: UInt64, resume: Resume)?

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    /// An ID for a new flow, so a finished flow cannot unregister a later one.
    func mintFlow() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        nextFlow &+= 1
        return nextFlow
    }

    /// Registers the flow's `resume` for `cancel()`. `false` if the presenter is already cancelled.
    func begin(_ flow: UInt64, resume: @escaping Resume) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !cancelled else {
            return false
        }
        pending = (flow, resume)
        return true
    }

    /// Unregisters `flow` once it has been resumed.
    func end(_ flow: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        if pending?.flow == flow {
            pending = nil
        }
    }

    /// Marks the presenter cancelled and hands back the flow in progress, if any, to end.
    func cancel() -> Resume? {
        lock.lock()
        defer { lock.unlock() }
        cancelled = true
        return pending?.resume
    }
}

extension HostedUIASWebAuthenticationSession: ASWebAuthenticationPresentationContextProviding {

    @MainActor
    package func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let webPresentation {
            return webPresentation
        }
        // An empty anchor has no window scene, so it never presents.
        #if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let ordered = scenes.filter { $0.activationState == .foregroundActive } + scenes
        let window = ordered.compactMap { scene in
            scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
        }.first
        return window ?? ASPresentationAnchor()
        #elseif canImport(AppKit)
        return NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}
#endif
