//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import InternalAWSCognitoAuth
#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import XCTest

/// `HostedUIASWebAuthenticationSession.cancel()`: before the
/// session starts, while it is showing, after it completed, and twice. A second resume of a checked
/// continuation traps, so every test reaching its end is also the "exactly one resume" assertion.
///
/// - Note: `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
///   `@Sendable` closures the API takes. XCTest runs one test at a time.
final class HostedUIPresenterCancellationTests: XCTestCase, @unchecked Sendable {

    private var presenter: HostedUIASWebAuthenticationSession!
    private var factory: ASWebAuthenticationSessionFactory!

    override func setUp() {
        presenter = HostedUIASWebAuthenticationSession()
        factory = ASWebAuthenticationSessionFactory()
        presenter.authenticationSessionFactory = factory.createSession(url:callbackURLScheme:completionHandler:)
    }

    override func tearDown() {
        presenter = nil
        factory = nil
    }

    /// A cancel that reaches the presenter before the flow does
    ///
    /// - Given: A presenter that was cancelled
    /// - When:
    ///    - showHostedUI is invoked
    /// - Then:
    ///    - It throws `HostedUIError.cancelled` without creating a session
    ///
    func testCancelBeforeShowingThrowsCancelledAndCreatesNothing() async {
        presenter.cancel()
        await assertCancelled { try await self.presenter.showHostedUI() }
        XCTAssertNil(factory.lastSession)
    }

    /// A cancel between creating the session and starting it
    ///
    /// - Given: A flow whose session has been created, and whose `start()` is queued on the main queue
    /// - When:
    ///    - the presenter is cancelled at that moment
    /// - Then:
    ///    - The flow throws `HostedUIError.cancelled`
    ///    - The session is never started
    ///
    func testCancelBeforeStartNeverStartsTheSession() async throws {
        let presenter = presenter!
        factory.onCreate = { _ in presenter.cancel() }
        await assertCancelled { try await presenter.showHostedUI() }
        let created = try XCTUnwrap(factory.lastSession)
        let started = await MainActor.run { created.startCount }
        XCTAssertEqual(started, 0)
    }

    /// A cancel while the browser is showing
    ///
    /// - Given: A started session whose completion handler has not fired
    /// - When:
    ///    - the presenter is cancelled, and the completion handler fires later
    /// - Then:
    ///    - The flow throws `HostedUIError.cancelled`, once
    ///    - The session is dismissed (`cancel()` called once) and no longer retained
    ///
    func testCancelWhileShowingDismissesAndResumesOnce() async throws {
        factory.mockedURL = URL(string: "https://test.com?code=late")
        factory.mockInvokesCallbackOnStart = false
        let started = expectation(description: "session started")
        factory.onStart = { started.fulfill() }
        let presenter = presenter!
        let flow = Task { try await presenter.showHostedUI() }
        await fulfillment(of: [started], timeout: 5)

        presenter.cancel()
        await assertCancelled { try await flow.value }

        let session = try XCTUnwrap(factory.lastSession)
        await MainActor.run { session.invokeCallback() }
        let cancels = await MainActor.run { session.cancelCount }
        XCTAssertEqual(cancels, 1)
        XCTAssertNil(presenter.authenticationSession)
    }

    /// The system answering the dismissal with its own completion
    ///
    /// - Given: A started session that calls its completion handler with `canceledLogin` when cancelled
    /// - When:
    ///    - the presenter is cancelled
    /// - Then:
    ///    - The flow throws `HostedUIError.cancelled`, once
    ///
    func testCancelWhoseSessionAlsoCompletesResumesOnce() async {
        factory.mockInvokesCallbackOnStart = false
        factory.mockInvokesCallbackOnCancel = true
        let started = expectation(description: "session started")
        factory.onStart = { started.fulfill() }
        let presenter = presenter!
        let flow = Task { try await presenter.showHostedUI() }
        await fulfillment(of: [started], timeout: 5)

        presenter.cancel()
        await assertCancelled { try await flow.value }
    }

    /// A cancel after the flow completed
    ///
    /// - Given: A flow that returned its query items
    /// - When:
    ///    - the presenter is cancelled, twice
    /// - Then:
    ///    - Nothing happens: the completed session is not cancelled, and nothing is resumed again
    ///    - A later flow on the same presenter throws `HostedUIError.cancelled` (the cancel is sticky)
    ///
    func testCancelAfterCompletionIsANoOpAndSticky() async throws {
        factory.mockedURL = URL(string: "https://test.com?code=abc")
        let items = try await presenter.showHostedUI()
        XCTAssertEqual(items.first?.value, "abc")

        presenter.cancel()
        presenter.cancel()
        await MainActor.run {}
        let completed = try XCTUnwrap(factory.lastSession)
        let cancels = await MainActor.run { completed.cancelCount }
        XCTAssertEqual(cancels, 0)

        await assertCancelled { try await self.presenter.showHostedUI() }
    }

    /// Cancelling twice while showing
    ///
    /// - Given: A started session
    /// - When:
    ///    - the presenter is cancelled twice
    /// - Then:
    ///    - The flow throws `HostedUIError.cancelled` once, and the session is dismissed once
    ///
    func testCancelTwiceIsIdempotent() async throws {
        factory.mockInvokesCallbackOnStart = false
        let started = expectation(description: "session started")
        factory.onStart = { started.fulfill() }
        let presenter = presenter!
        let flow = Task { try await presenter.showHostedUI() }
        await fulfillment(of: [started], timeout: 5)

        presenter.cancel()
        presenter.cancel()
        await assertCancelled { try await flow.value }
        await MainActor.run {}
        let session = try XCTUnwrap(factory.lastSession)
        let cancels = await MainActor.run { session.cancelCount }
        XCTAssertEqual(cancels, 1)
    }

    /// The protocol's default for presenters that cannot be cancelled
    ///
    /// - Given: A `HostedUISessionBehavior` that does not implement `cancel()`
    /// - When:
    ///    - `cancel()` is called
    /// - Then:
    ///    - Nothing happens (the plugin's test doubles are unchanged): the presenter still shows, and answers
    ///
    func testTheDefaultCancelDoesNothing() async throws {
        let presenter: any HostedUISessionBehavior = NonCancellablePresenter()
        presenter.cancel()
        let items = try await presenter.showHostedUI(
            url: URL(string: "https://test.com")!,
            callbackScheme: "https",
            inPrivate: false,
            presentationAnchor: nil
        )
        XCTAssertEqual(items, [URLQueryItem(name: "code", value: "shown")])
    }

    private func assertCancelled(
        _ body: @escaping @Sendable () async throws -> [URLQueryItem],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await body()
            XCTFail("Expected HostedUIError.cancelled", file: file, line: line)
        } catch let error as HostedUIError {
            XCTAssertEqual(error, .cancelled, file: file, line: line)
        } catch {
            XCTFail("Expected HostedUIError.cancelled, got \(error)", file: file, line: line)
        }
    }
}

private struct NonCancellablePresenter: HostedUISessionBehavior {
    func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: EnginePresentationAnchor?
    ) async throws -> [URLQueryItem] {
        [URLQueryItem(name: "code", value: "shown")]
    }
}
#else

import XCTest

/// On tvOS and watchOS the presenter still only throws "only available", and `cancel()` does nothing.
final class HostedUIPresenterCancellationTests: XCTestCase {

    /// - Given: A presenter on a platform without a hosted UI
    /// - When:
    ///    - it is cancelled, then asked to show
    /// - Then:
    ///    - It throws the "only available" service message
    ///
    func testCancelLeavesTheUnavailableErrorAlone() async {
        let presenter = HostedUIASWebAuthenticationSession()
        presenter.cancel()
        do {
            _ = try await presenter.showHostedUI(
                url: URL(string: "https://test.com")!,
                callbackScheme: "https",
                inPrivate: false,
                presentationAnchor: nil
            )
            XCTFail("Expected HostedUIError.serviceMessage")
        } catch let error as HostedUIError {
            XCTAssertEqual(error, .serviceMessage("HostedUI is only available in iOS, macOS and visionOS"))
        } catch {
            XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
        }
    }
}
#endif
