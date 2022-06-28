//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

class InitializeFetchAuthSessionTests: XCTestCase {

    func testInitializeUserPoolTokens() {
        let expectation = expectation(description: "initializeUserPool")
        let action = InitializeFetchAuthSessionWithUserPool(tokens: .testData)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(withDispatcher: MockDispatcher { event in

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

        waitForExpectations(timeout: 0.1)
    }

}
