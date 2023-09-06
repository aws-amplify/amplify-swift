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

    func testShowHostedUI_withUrlInCallback_withQueryItems_shouldReturnQueryItems() {
        let expectation = expectation(description: "showHostedUI")
        factory.mockedURL = createURL(queryItems: [.init(name: "name", value: "value")])

        session.showHostedUI() { result in
            do {
                let queryItems = try result.get()
                XCTAssertEqual(queryItems.count, 1)
                XCTAssertEqual(queryItems.first?.name, "name")
                XCTAssertEqual(queryItems.first?.value, "value")
            } catch {
                XCTFail("Expected .success(queryItems), got \(result)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testShowHostedUI_withUrlInCallback_withoutQueryItems_shouldReturnEmptyQueryItems() {
        let expectation = expectation(description: "showHostedUI")
        factory.mockedURL = createURL()

        session.showHostedUI() { result in
            do {
                let queryItems = try result.get()
                XCTAssertTrue(queryItems.isEmpty)
            } catch {
                XCTFail("Expected .success(queryItems), got \(result)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testShowHostedUI_withUrlInCallback_withErrorInQueryItems_shouldReturnServiceMessageError() {
        let expectation = expectation(description: "showHostedUI")
        factory.mockedURL = createURL(
            queryItems: [
                .init(name: "error", value: "Error."),
                .init(name: "error_description", value: "Something went wrong")
            ]
        )

        session.showHostedUI() { result in
            do {
                _ = try result.get()
                XCTFail("Expected failure(.serviceMessage), got \(result)")
            } catch let error as HostedUIError {
                if case .serviceMessage(let message) = error {
                    XCTAssertEqual(message, "Error. Something went wrong")
                } else {
                    XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
                }
            } catch {
                XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testShowHostedUI_withASWebAuthenticationSessionErrors_shouldReturnRightError() {
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
            let expectation = expectation(description: "showHostedUI for error \(code)")
            session.showHostedUI() { result in
                do {
                    _ = try result.get()
                    XCTFail("Expected failure(.\(expectedError)), got \(result)")
                } catch let error as HostedUIError {
                    XCTAssertEqual(error, expectedError)
                } catch {
                    XCTFail("Expected HostedUIError.\(expectedError), got \(error)")
                }
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }
    
    func testShowHostedUI_withOtherError_shouldReturnUnknownError() {
        factory.mockedError = CancellationError()
        let expectation = expectation(description: "showHostedUI")
        session.showHostedUI() { result in
            do {
                _ = try result.get()
                XCTFail("Expected failure(.unknown), got \(result)")
            } catch let error as HostedUIError {
                XCTAssertEqual(error, .unknown)
            } catch {
                XCTFail("Expected HostedUIError.unknown, got \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
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
}

extension HostedUIASWebAuthenticationSession {
    func showHostedUI(callback: @escaping (Result<[URLQueryItem], HostedUIError>) -> Void) {
        showHostedUI(
            url: URL(string: "https://test.com")!,
            callbackScheme: "https",
            inPrivate: false,
            presentationAnchor: nil,
            callback: callback)
    }
}
#else

@testable import AWSCognitoAuthPlugin
import XCTest

class HostedUIASWebAuthenticationSessionTests: XCTestCase {
    func testShowHostedUI_shouldThrowServiceError() {
        let expectation = expectation(description: "showHostedUI")
        let session = HostedUIASWebAuthenticationSession()
        session.showHostedUI(
            url: URL(string: "https://test.com")!,
            callbackScheme: "https",
            inPrivate: false,
            presentationAnchor: nil
        ) { result in
            do {
                _ = try result.get()
                XCTFail("Expected failure(.serviceMessage), got \(result)")
            } catch let error as HostedUIError {
                if case .serviceMessage(let message) = error {
                    XCTAssertEqual(message, "HostedUI is only available in iOS and macOS")
                } else {
                    XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
                }
            } catch {
                XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}

#endif
