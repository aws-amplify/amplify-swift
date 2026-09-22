//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class InitializeFetchAuthSessionTests: XCTestCase, @unchecked Sendable {

    func testInitializeUserPoolTokens()  async {
        let expectation = expectation(description: "initializeUserPool")
        let action = InitializeFetchAuthSessionWithUserPool(signedInData: .testData)

        let environment = Defaults.makeDefaultAuthEnvironment()

        await action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchAuthSessionEvent else {
                    XCTFail("Expected event to be FetchAuthSessionEvent")
                    return
                }

                if case .fetchAuthenticatedIdentityID = event.eventType {
                    expectation.fulfill()
                }

            },
            environment: environment
        )

        await fulfillment(
            of: [expectation],
            timeout: 0.1
        )
    }

}
