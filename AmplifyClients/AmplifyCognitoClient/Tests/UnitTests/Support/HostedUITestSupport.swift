//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The browser a `FakeSessionEngine` shows a hosted-UI sign-in in: the test decides when and how it ends.
///
/// A shown sign-in waits until the test calls `finish(_:)`, or until its task is cancelled (the lease
/// interrupted it, which is how the real presenter's `cancel()` is reached). What a cancelled sign-in does is
/// `afterCancel`: throw at once, as a browser that was dismissed; or keep waiting for `finish(_:)`, as a flow
/// whose code exchange was already in flight, so a test can deliver a late `.done`.
///
/// - Note: `@unchecked Sendable`: every property below is only touched while holding `lock`.
final class FakeBrowser: @unchecked Sendable {

    enum AfterCancel {
        /// The browser is dismissed: the sign-in throws `CancellationError`.
        case dismiss
        /// The sign-in keeps waiting for `finish(_:)`: its result comes too late for anyone.
        case keepRunning
    }

    /// One arrival per sign-in shown.
    let shown = Gate(isOpen: true)

    private let lock = NSLock()
    private var afterCancel: AfterCancel
    private var waiting: CheckedContinuation<EngineStepResult, Error>?
    private var answer: Result<EngineStepResult, Error>?
    private var cancelledBeforeWaiting = false
    private var cancels = 0
    private var requests: [EngineWebUISignInRequest] = []
    private var answersWith: EngineStepResult?

    init(afterCancel: AfterCancel = .dismiss) {
        self.afterCancel = afterCancel
    }

    /// How many shown sign-ins were cancelled while showing.
    var cancelCount: Int {
        withLock { cancels }
    }

    /// The payload the default answer would have committed, for `finishWithDefault()`.
    var defaultAnswer: EngineStepResult? {
        withLock { answersWith }
    }

    /// Shows one sign-in, and waits for its end. `result` is what `finishWithDefault()` answers.
    func show(_ request: EngineWebUISignInRequest, answering result: EngineStepResult) async throws -> EngineStepResult {
        withLock {
            requests.append(request)
            answersWith = result
        }
        await shown.pass()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let ready: Result<EngineStepResult, Error>? = withLock {
                    if let answer {
                        self.answer = nil
                        return answer
                    }
                    if cancelledBeforeWaiting, afterCancel == .dismiss {
                        return .failure(CancellationError())
                    }
                    waiting = continuation
                    return nil
                }
                if let ready {
                    continuation.resume(with: ready)
                }
            }
        } onCancel: {
            cancelled()
        }
    }

    /// Ends the sign-in showing, or the next one to show.
    func finish(_ result: Result<EngineStepResult, Error>) {
        let continuation = withLock { () -> CheckedContinuation<EngineStepResult, Error>? in
            guard let waiting else {
                answer = result
                return nil
            }
            self.waiting = nil
            return waiting
        }
        continuation?.resume(with: result)
    }

    /// Ends the sign-in showing with the fake engine's default `.done`.
    func finishWithDefault() {
        guard let result = defaultAnswer else {
            preconditionFailure("no sign-in has been shown")
        }
        finish(.success(result))
    }

    private func cancelled() {
        let continuation = withLock { () -> CheckedContinuation<EngineStepResult, Error>? in
            cancels += 1
            guard afterCancel == .dismiss else {
                return nil
            }
            guard let waiting else {
                cancelledBeforeWaiting = true
                return nil
            }
            self.waiting = nil
            return waiting
        }
        continuation?.resume(throwing: CancellationError())
    }

    private func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

enum HostedUIFixtures {

    /// The user pool with a hosted UI: `auth.oauth` with one sign-in and one sign-out redirect URI.
    static let userPool = AuthClientConfiguration.UserPool(
        poolId: StorageFixtures.userPoolId,
        appClientId: "app-client-1",
        region: "us-east-1",
        oauth: AuthClientConfiguration.OAuth(
            domain: "auth.example.com",
            scopes: ["openid", "email", "profile"],
            redirectSignInURIs: ["myapp://signin/"],
            redirectSignOutURIs: ["myapp://signout/"]
        )
    )

    /// Both pools and a hosted UI, in the same namespace as `ClientFixtures.configuration`.
    static let configuration = ClientFixtures.make(userPool: userPool, identityPool: ClientFixtures.identityPool)

    /// The window to anchor sheets to: one per test process, made on first use. The fake engine and the
    /// presenter spy never show it, and no test closes it, so the hosted-UI tests can share it.
    ///
    /// Made on first use, not up front: a process's first `UIWindow()` can block for minutes on a just-booted,
    /// loaded simulator while SpringBoard bootstraps the test host.
    @MainActor
    static func window() -> AuthClientPresentationAnchor {
        sharedWindow
    }

    @MainActor
    private static let sharedWindow: AuthClientPresentationAnchor = {
        #if canImport(UIKit)
        return UIWindow()
        #else
        return NSWindow()
        #endif
    }()

    /// A payload signed in through the hosted UI, sharing the browser's cookies unless `ephemeral`.
    static func hostedUIPayload(_ username: String = "alice", ephemeral: Bool = false, version: Int = 1) -> FakePayload {
        var payload = FakePayload.signedIn(username, version: version)
        payload.hostedUIShared = ephemeral ? nil : true
        return payload
    }
}
#endif
