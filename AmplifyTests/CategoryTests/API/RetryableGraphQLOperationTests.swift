//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class RetryableGraphQLOperationTests: XCTestCase {
    let testApiName = "apiName"

    /// Given: a RetryableGraphQLOperation with a maxRetries of 2
    /// When: the request fails the first attempt with a .signedOut error
    /// Then: the request is re-tried and resultListener called
    func testShouldRetryOperation() {
        let maxRetries = 2
        var attempt = 0

        let requestFactoryExpectation = expectation(description: "Retry factory called \(maxRetries) times")
        requestFactoryExpectation.expectedFulfillmentCount = maxRetries
        let resultExpectation = expectation(description: "Result called")

        let resultListener: ResultListener = { _ in
            resultExpectation.fulfill()
        }

        let requestFactory: RequestFactory = { completion in
            requestFactoryExpectation.fulfill()
            self.makeTestRequestAsync(completion: completion)
        }

        let operation = RetryableGraphQLOperation<Payload>(requestFactory: requestFactory,
                                                           maxRetries: maxRetries,
                                                           resultListener: resultListener) { _, wrappedListener in

            // simulate an error at first attempt
            if attempt == 0 {
                wrappedListener(
                    .failure(self.makeSignedOutAuthError())
                )
            } else {
                wrappedListener(.success(.success("")))
            }
            attempt += 1
            return self.makeTestOperation()
        }
        operation.main()

        wait(for: [requestFactoryExpectation, resultExpectation], timeout: 10)
    }

    /// Given: a RetryableGraphQLOperation with a maxRetries of 1
    /// When: the request fails the first attempt with a .signedOut error
    /// Then: the request is not re-tried
    func testShouldNotRetryOperationWithMaxRetriesOne() {
        let maxRetries = 1

        let requestFactoryExpectation = expectation(description: "Retry factory called \(maxRetries) times")
        requestFactoryExpectation.expectedFulfillmentCount = maxRetries
        let resultExpectation = expectation(description: "Result called")

        let resultListener: ResultListener = { _ in
            resultExpectation.fulfill()
        }

        let requestFactory: RequestFactory = { completion in
            requestFactoryExpectation.fulfill()
            completion(self.makeTestRequest())
        }

        let operation = RetryableGraphQLOperation<Payload>(requestFactory: requestFactory,
                                                           maxRetries: maxRetries,
                                                           resultListener: resultListener) { _, wrappedListener in

            wrappedListener(
                .failure(self.makeSignedOutAuthError())
            )
            return self.makeTestOperation()
        }
        operation.main()

        wait(for: [requestFactoryExpectation, resultExpectation], timeout: 10)
    }

    /// Given: a RetryableGraphQLOperation with a maxRetries of 2
    /// When: the request fails both attempts
    /// Then: the request is re-tried only twice and resultListener called
    func testNotShouldRetryOperation() {
        let maxRetries = 2

        let requestFactoryExpectation = expectation(description: "Retry factory called \(maxRetries) times")
        requestFactoryExpectation.expectedFulfillmentCount = maxRetries
        let resultExpectation = expectation(description: "Result called")

        let resultListener: ResultListener = { _ in
            resultExpectation.fulfill()
        }

        let requestFactory: RequestFactory = { completion in
            requestFactoryExpectation.fulfill()
            completion(self.makeTestRequest())
        }

        let operation = RetryableGraphQLOperation<Payload>(requestFactory: requestFactory,
                                                           maxRetries: maxRetries,
                                                           resultListener: resultListener) { _, wrappedListener in

            // simulate an error for both attempts
            wrappedListener(
                .failure(self.makeSignedOutAuthError())
            )
            return self.makeTestOperation()
        }
        operation.main()

        wait(for: [requestFactoryExpectation, resultExpectation], timeout: 10)
    }
}

// MARK: - Test helpers
extension RetryableGraphQLOperationTests {
    private func makeTestRequest() -> GraphQLRequest<Payload> {
        GraphQLRequest<Payload>(apiName: testApiName,
                                       document: "",
                                       responseType: Payload.self)
    }

    private func makeTestRequestAsync(completion: @escaping (GraphQLRequest<Payload>) -> Void ) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            let request = GraphQLRequest<Payload>(apiName: self.testApiName,
                                           document: "",
                                           responseType: Payload.self)
            completion(request)
        }

    }

    private func makeTestOperation() -> GraphQLOperation<Payload> {
        let requestOptions = GraphQLOperationRequest<Payload>.Options(pluginOptions: nil)
        let operationRequest = GraphQLOperationRequest<Payload>(apiName: testApiName,
                                                                operationType: .subscription,
                                                                document: "",
                                                                responseType: Payload.self,
                                                                options: requestOptions)
        return GraphQLOperation<Payload>(categoryType: .dataStore,
                                         eventName: "eventName",
                                         request: operationRequest)
    }

    func makeSignedOutAuthError() -> APIError {
        return APIError.operationError("Error", "", AuthError.signedOut("AuthError", ""))
    }

    /// Convenience type alias
    private typealias Payload = String
    private typealias ResultListener = RetryableGraphQLOperation<Payload>.OperationResultListener
    private typealias RequestFactory = RetryableGraphQLOperation<Payload>.RequestFactory
}
