//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import Amplify
import AuthenticationServices
@testable import AWSCognitoAuthPlugin
import XCTest

class HostedUIASWebAuthenticationSessionTests: XCTestCase {
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

    private func createURL(queryItems: [URLQueryItem] = []) -> URL {
        var components = URLComponents(string: "https://test.com")!
        components.queryItems = queryItems
        return components.url!
    }
}

class ASWebAuthenticationSessionFactory {
    var mockedURL: URL?
    var mockedError: Error?
    var mockCanStart: Bool?

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
        return session
    }
}

class MockASWebAuthenticationSession: ASWebAuthenticationSession {
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
    
    var mockedURL: URL? = nil
    var mockedError: Error? = nil
    override func start() -> Bool {
        callback(mockedURL, mockedError)
        return presentationContextProvider?.presentationAnchor(for: self) != nil
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
            presentationAnchor: nil)
    }
}
#else

@testable import AWSCognitoAuthPlugin
import XCTest

class HostedUIASWebAuthenticationSessionTests: XCTestCase {
    func testShowHostedUI_shouldThrowServiceError() async {
        let session = HostedUIASWebAuthenticationSession()
        do {
            _ = try await session.showHostedUI(
                url: URL(string: "https://test.com")!,
                callbackScheme: "https",
                inPrivate: false,
                presentationAnchor: nil)
        } catch let error as HostedUIError {
            if case .serviceMessage(let message) = error {
                XCTAssertEqual(message, "HostedUI is only available in iOS and macOS")
            } else {
                XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
            }
        } catch {
            XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
        }
    }
}

#endif
