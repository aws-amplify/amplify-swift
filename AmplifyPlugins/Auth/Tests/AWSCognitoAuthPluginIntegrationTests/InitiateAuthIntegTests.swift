//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

////
//// Copyright Amazon.com Inc. or its affiliates.
//// All Rights Reserved.
////
//// SPDX-License-Identifier: Apache-2.0
////
//
//import XCTest
//
//import AWSCognitoIdentityProvider
//
//
//@testable import AWSCognitoAuthPlugin
//
//struct MockConfigurationErrorEnvironment: Environment { }
//
//class InitiateAuthIntegTests: XCTestCase {
//
//    static let networkTimeout: TimeInterval = 120
//    let environment = Defaults.makeDefaultAuthEnvironment()
//
//    func testInitiateAuthActionPropagatesSuccess() {
//
//        let action = InitiateAuthSRP(username: "user1", password: "")
//        let errorEventSent = expectation(description: "errorEventSent")
//
//        let dispatcher = IntegrationTestMockDispatcher { event in
//            errorEventSent.fulfill()
//            guard let event = event as? SRPSignInEvent else {
//                XCTFail("Expected event to be SRPSignInEvent")
//                return
//            }
//
//            guard case .respondPasswordVerifier(let srpStateData, let authOutputResponse) = event.eventType else {
//                XCTFail("Expected event to be .respondPasswordVerifier but received: \(event.eventType)")
//                return
//            }
//
//            XCTAssertNotNil(srpStateData)
//            XCTAssertNotNil(authOutputResponse)
//        }
//
//        action.execute(
//            withDispatcher: dispatcher,
//            environment: environment
//        )
//
//        waitForExpectations(timeout: InitiateAuthIntegTests.networkTimeout)
//    }
//
//    func testInitiateAuthActionPropagatesServiceError() {
//        let action = InitiateAuthSRP(username: "INVALID_USER", password: "")
//        let errorEventSent = expectation(description: "errorEventSent")
//
//        let dispatcher = IntegrationTestMockDispatcher { event in
//            errorEventSent.fulfill()
//            guard let event = event as? SRPSignInEvent else {
//                XCTFail("Expected event to be SRPSignInEvent")
//                return
//            }
//
//            guard case .throwAuthError(let authError) = event.eventType else {
//                XCTFail("Expected event to be .throwAuthError but received: \(event.eventType)")
//                return
//            }
//
//            guard case .service(let message) = authError else {
//                XCTFail("Expected error to be .service but received: \(authError)")
//                return
//            }
//            XCTAssertNotNil(message)
//        }
//
//        action.execute(
//            withDispatcher: dispatcher,
//            environment: environment
//        )
//
//        waitForExpectations(timeout: InitiateAuthIntegTests.networkTimeout)
//    }
//
//    func testInitiateAuthActionPropagatesConfigurationError() {
//        let action = InitiateAuthSRP(username: "user1", password: "")
//        let errorEventSent = expectation(description: "errorEventSent")
//
//        let dispatcher = IntegrationTestMockDispatcher { event in
//            errorEventSent.fulfill()
//            guard let event = event as? SRPSignInEvent else {
//                XCTFail("Expected event to be SRPSignInEvent")
//                return
//            }
//
//            guard case .throwAuthError(let authError) = event.eventType else {
//                XCTFail("Expected event to be .throwAuthError but received: \(event.eventType)")
//                return
//            }
//
//            guard case .configuration(let message) = authError else {
//                XCTFail("Expected error to be .configuration but received: \(authError)")
//                return
//            }
//            XCTAssertNotNil(message)
//        }
//
//        action.execute(
//            withDispatcher: dispatcher,
//            environment: MockConfigurationErrorEnvironment()
//        )
//
//        waitForExpectations(timeout: InitiateAuthIntegTests.networkTimeout)
//    }
//}
