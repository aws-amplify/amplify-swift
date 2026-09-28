//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import InternalAWSCognitoAuth
#if os(iOS) || os(macOS) || os(visionOS)
import Amplify
import AuthenticationServices
import XCTest
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class HostedUIASWebAuthenticationSessionTests: XCTestCase, @unchecked Sendable {
    private var session: HostedUIASWebAuthenticationSession!
    private var factory: ASWebAuthenticationSessionFactory!

    override func setUp() {
        session = HostedUIASWebAuthenticationSession()
        factory = ASWebAuthenticationSessionFactory()
        session.authenticationSessionFactory = factory.createSession(url:callbackURLScheme:completionHandler:)
    }

    override func tearDown() {
        session = nil
        factory = nil
    }

    /// Given: A HostedUIASWebAuthenticationSession
    /// When: showHostedUI is invoked and the session factory returns a URL with query items
    /// Then: An array of query items should be returned
    func testShowHostedUI_withUrlInCallback_withQueryItems_shouldReturnQueryItems() async throws {
        factory.mockedURL = createURL(queryItems: [.init(name: "name", value: "value")])
        let queryItems = try await session.showHostedUI()
        XCTAssertEqual(queryItems.count, 1)
        XCTAssertEqual(queryItems.first?.name, "name")
        XCTAssertEqual(queryItems.first?.value, "value")
    }

    /// Given: A HostedUIASWebAuthenticationSession
    /// When: showHostedUI is invoked and the session factory returns a URL without query items
    /// Then: An empty array should be returned
    func testShowHostedUI_withUrlInCallback_withoutQueryItems_shouldReturnEmptyQueryItems() async throws {
        factory.mockedURL = createURL()
        let queryItems = try await session.showHostedUI()
        XCTAssertTrue(queryItems.isEmpty)
    }

    /// Given: A HostedUIASWebAuthenticationSession
    /// When: showHostedUI is invoked and the session factory returns a URL with query items representing errors
    /// Then: A HostedUIError.serviceMessage should be returned
    func testShowHostedUI_withUrlInCallback_withErrorInQueryItems_shouldReturnServiceMessageError() async {
        factory.mockedURL = createURL(
            queryItems: [
                .init(name: "error", value: "Error."),
                .init(name: "error_description", value: "Something went wrong")
            ]
        )
        do {
            _ = try await session.showHostedUI()
        } catch let error as HostedUIError {
            if case .serviceMessage(let message) = error {
                XCTAssertEqual(message, "Error. Something went wrong")
            } else {
                XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
            }
        } catch {
            XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
        }
    }

    /// Given: A HostedUIASWebAuthenticationSession
    /// When: showHostedUI is invoked and the session factory returns ASWebAuthenticationSessionErrors
    /// Then: A HostedUIError corresponding to the error code should be returned
    func testShowHostedUI_withASWebAuthenticationSessionErrors_shouldReturnRightError() async {
        let errorMap: [ASWebAuthenticationSessionError.Code: HostedUIError] = [
            .canceledLogin: .cancelled,
            .presentationContextNotProvided: .invalidContext,
            .presentationContextInvalid: .invalidContext
        ]

        let errorCodes: [ASWebAuthenticationSessionError.Code] = [
            .canceledLogin,
            .presentationContextNotProvided,
            .presentationContextInvalid,
            .init(rawValue: 500)!
        ]

        for code in errorCodes {
            factory.mockedError = ASWebAuthenticationSessionError(code)
            let expectedError = errorMap[code] ?? .unknown
            do {
                _ = try await session.showHostedUI()
            } catch let error as HostedUIError {
                XCTAssertEqual(error, expectedError)
            } catch {
                XCTFail("Expected HostedUIError.\(expectedError), got \(error)")
            }
        }
    }

    /// Given: A HostedUIASWebAuthenticationSession
    /// When: showHostedUI is invoked and the session factory returns an error
    /// Then: A HostedUIError.unknown should be returned
    func testShowHostedUI_withOtherError_shouldReturnUnknownError() async {
        factory.mockedError = CancellationError()
        do {
            _ = try await session.showHostedUI()
        } catch let error as HostedUIError {
            XCTAssertEqual(error, .unknown)
        } catch {
            XCTFail("Expected HostedUIError.unknown, got \(error)")
        }
    }

    /// Given: A HostedUIASWebAuthenticationSession
    /// When: showHostedUI is invoked and the session factory returns an error
    /// Then: A HostedUIError.unableToStartASWebAuthenticationSession should be returned
    func testShowHostedUI_withUnableToStartError_shouldReturnServiceError() async {
        factory.mockCanStart = false
        do {
            _ = try await session.showHostedUI()
        } catch let error as HostedUIError {
            XCTAssertEqual(error, .unableToStartASWebAuthenticationSession)
        } catch {
            XCTFail("Expected HostedUIError.unknown, got \(error)")
        }
    }

    /// Test that a `false` return from `start()` does not leave the caller waiting forever
    ///
    /// - Given: An `ASWebAuthenticationSession` whose `canStart` is `true` but whose `start()`
    ///   returns `false` without ever invoking its completion handler
    /// - When:
    ///    - showHostedUI is invoked
    /// - Then:
    ///    - A HostedUIError.unableToStartASWebAuthenticationSession should be thrown
    ///
    func testShowHostedUI_whenStartReturnsFalse_shouldThrowUnableToStartError() async {
        factory.mockCanStart = true
        factory.mockStartResult = false
        factory.mockInvokesCallbackOnStart = false

        let completed = expectation(description: "showHostedUI completed")
        let session = session!
        Task {
            do {
                _ = try await session.showHostedUI()
                XCTFail("Expected HostedUIError.unableToStartASWebAuthenticationSession")
            } catch let error as HostedUIError {
                XCTAssertEqual(error, .unableToStartASWebAuthenticationSession)
            } catch {
                XCTFail("Expected HostedUIError.unableToStartASWebAuthenticationSession, got \(error)")
            }
            completed.fulfill()
        }
        await fulfillment(of: [completed], timeout: 5)
    }

    /// Test that the continuation is resumed exactly once when `start()` returns `false` after
    /// the completion handler has already fired
    ///
    /// - Given: An `ASWebAuthenticationSession` whose `start()` invokes its completion handler
    ///   with a URL and then returns `false`
    /// - When:
    ///    - showHostedUI is invoked
    /// - Then:
    ///    - The query items from the completion handler should be returned, and the
    ///      continuation should not be resumed a second time
    ///
    func testShowHostedUI_whenStartReturnsFalseAfterCallback_shouldResumeOnlyOnce() async throws {
        factory.mockedURL = createURL(queryItems: [.init(name: "name", value: "value")])
        factory.mockStartResult = false
        let queryItems = try await session.showHostedUI()
        XCTAssertEqual(queryItems.count, 1)
        XCTAssertEqual(queryItems.first?.name, "name")
    }

    /// Test that a completion handler firing after `start()` has returned `false` is ignored
    ///
    /// - Given: An `ASWebAuthenticationSession` whose `start()` returns `false` without invoking its
    ///   completion handler, and whose completion handler fires later
    /// - When:
    ///    - showHostedUI is invoked, and the completion handler fires after the flow has ended
    /// - Then:
    ///    - A HostedUIError.unableToStartASWebAuthenticationSession should be thrown
    ///    - The late completion handler should not resume the continuation a second time
    ///
    func testShowHostedUI_whenCallbackFiresAfterStartReturnsFalse_shouldResumeOnlyOnce() async throws {
        factory.mockedURL = createURL(queryItems: [.init(name: "name", value: "value")])
        factory.mockStartResult = false
        factory.mockInvokesCallbackOnStart = false

        let completed = expectation(description: "showHostedUI completed")
        let session = session!
        Task {
            do {
                _ = try await session.showHostedUI()
                XCTFail("Expected HostedUIError.unableToStartASWebAuthenticationSession")
            } catch let error as HostedUIError {
                XCTAssertEqual(error, .unableToStartASWebAuthenticationSession)
            } catch {
                XCTFail("Expected HostedUIError.unableToStartASWebAuthenticationSession, got \(error)")
            }
            completed.fulfill()
        }
        await fulfillment(of: [completed], timeout: 5)

        // A second resume of a checked continuation traps, so reaching the end of the test is the assertion.
        let lateSession = try XCTUnwrap(factory.lastSession)
        await MainActor.run { lateSession.invokeCallback() }
        XCTAssertNil(session.authenticationSession)
    }

    /// Test that the `ASWebAuthenticationSession` is retained for the duration of the flow
    ///
    /// - Given: An `ASWebAuthenticationSession` whose `start()` returns `true` and whose
    ///   completion handler fires later
    /// - When:
    ///    - showHostedUI is invoked and the session has started
    /// - Then:
    ///    - The in-flight `ASWebAuthenticationSession` should be retained by the adapter
    ///    - Once the completion handler fires, the query items should be returned and the
    ///      session should no longer be retained
    ///
    func testShowHostedUI_whileInFlight_shouldRetainAuthenticationSession() async throws {
        factory.mockedURL = createURL(queryItems: [.init(name: "name", value: "value")])
        factory.mockInvokesCallbackOnStart = false
        let started = expectation(description: "session started")
        factory.onStart = { started.fulfill() }

        let session = session!
        let task = Task { try await session.showHostedUI() }
        await fulfillment(of: [started], timeout: 5)

        let inFlight = try XCTUnwrap(factory.lastSession)
        XCTAssertTrue(session.authenticationSession === inFlight)

        inFlight.invokeCallback()
        let queryItems = try await task.value
        XCTAssertEqual(queryItems.first?.name, "name")
        XCTAssertNil(session.authenticationSession)
    }

    private func createURL(queryItems: [URLQueryItem] = []) -> URL {
        var components = URLComponents(string: "https://test.com")!
        components.queryItems = queryItems
        return components.url!
    }
}

// `@unchecked Sendable` so `createSession` can be used as the `@Sendable` factory the production
// type now expects. The mocked fields are set by a single test before use.
final class ASWebAuthenticationSessionFactory: @unchecked Sendable {
    var mockedURL: URL?
    var mockedError: Error?
    var mockCanStart: Bool?
    var mockStartResult: Bool?
    var mockInvokesCallbackOnStart = true
    var onStart: (() -> Void)?
    var mockInvokesCallbackOnCancel = false
    /// Runs as each session is created, before the adapter queues its `start()`.
    var onCreate: ((MockASWebAuthenticationSession) -> Void)?
    private(set) var lastSession: MockASWebAuthenticationSession?

    func createSession(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) -> ASWebAuthenticationSession {
        let session = MockASWebAuthenticationSession(
            url: URL,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completionHandler
        )
        session.mockedURL = mockedURL
        session.mockedError = mockedError
        session.mockCanStart = mockCanStart ?? true
        session.mockStartResult = mockStartResult
        session.mockInvokesCallbackOnStart = mockInvokesCallbackOnStart
        session.onStart = onStart
        session.mockInvokesCallbackOnCancel = mockInvokesCallbackOnCancel
        lastSession = session
        onCreate?(session)
        return session
    }
}

// `@unchecked Sendable`: returned from the `@Sendable` session factory. `ASWebAuthenticationSession`
// is an NSObject subclass driven on the main thread by the system.
final class MockASWebAuthenticationSession: ASWebAuthenticationSession, @unchecked Sendable {
    private var callback: ASWebAuthenticationSession.CompletionHandler
    override init(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) {
        self.callback = completionHandler
        super.init(
            url: URL,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completionHandler
        )
    }

    var mockedURL: URL?
    var mockedError: Error?
    var mockStartResult: Bool?
    var mockInvokesCallbackOnStart = true
    var onStart: (() -> Void)?
    var mockInvokesCallbackOnCancel = false
    private(set) var startCount = 0
    private(set) var cancelCount = 0
    override func start() -> Bool {
        startCount += 1
        if mockInvokesCallbackOnStart {
            invokeCallback()
        }
        onStart?()
        if let mockStartResult {
            return mockStartResult
        }
        return presentationContextProvider?.presentationAnchor(for: self) != nil
    }

    func invokeCallback() {
        callback(mockedURL, mockedError)
    }

    /// Records the call; with `mockInvokesCallbackOnCancel`, answers as the system may, with
    /// `canceledLogin`.
    override func cancel() {
        cancelCount += 1
        if mockInvokesCallbackOnCancel {
            callback(nil, ASWebAuthenticationSessionError(.canceledLogin))
        }
    }

    var mockCanStart = true
    override var canStart: Bool {
        return mockCanStart
    }
}

extension HostedUIASWebAuthenticationSession {
    func showHostedUI() async throws -> [URLQueryItem] {
        return try await showHostedUI(
            url: URL(string: "https://test.com")!,
            callbackScheme: "https",
            inPrivate: false,
            presentationAnchor: nil
        )
    }
}
#else

import XCTest
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class HostedUIASWebAuthenticationSessionTests: XCTestCase, @unchecked Sendable {
    func testShowHostedUI_shouldThrowServiceError() async {
        let session = HostedUIASWebAuthenticationSession()
        do {
            _ = try await session.showHostedUI(
                url: URL(string: "https://test.com")!,
                callbackScheme: "https",
                inPrivate: false,
                presentationAnchor: nil
            )
        } catch let error as HostedUIError {
            if case .serviceMessage(let message) = error {
                XCTAssertEqual(message, "HostedUI is only available in iOS, macOS and visionOS")
            } else {
                XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
            }
        } catch {
            XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
        }
    }
}

#endif
