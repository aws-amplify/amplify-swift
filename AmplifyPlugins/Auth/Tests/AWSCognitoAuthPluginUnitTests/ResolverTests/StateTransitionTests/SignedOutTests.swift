//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

////
////  SignedOutTests.swift
////
////
////  Created by Schmelter, Tim on 1/6/21.
////
//
//import XCTest
//@testable import AWSCognitoAuthPlugin
//
//class SignedOutTests: XCTestCase {
//
//    var resolver: AuthenticationState.Resolver {
//        AuthenticationState.Resolver()
//    }
//
//    var testSignedOutData: SignedOutData {
//        guard case .initializedSignedOut(let signedOutData) =
//                AuthenticationEvent.initializedSignedOutTest.eventType else {
//            fatalError("Incorrect data for initializedSignedOut test event")
//        }
//        return signedOutData
//    }
//
//    var oldState: AuthenticationState {
//        .signedOut(.testData, .testData)
//    }
//
//    func testSignInRequested() {
//        let expectedState = AuthenticationState.signingIn(.testData, .testData)
//
//        let resolution = resolver.resolve(
//            oldState: oldState,
//            byApplying: AuthenticationEvent.signInRequestedTest
//        )
//        XCTAssertEqual(resolution.newState, expectedState)
//        XCTAssert(resolution.commands.first is InitiateAuthSRP)
//    }
//
//    func testError() {
//        let expected = AuthenticationState.error(nil, .testData)
//        XCTAssertEqual(
//            resolver.resolve(
//                oldState: oldState,
//                byApplying: AuthenticationEvent.errorTest
//            ).newState,
//            expected
//        )
//    }
//
//    func testUnsupported() {
//        func assertIfUnsupported(_ event: AuthenticationEvent) {
//            switch event.eventType {
//            case .configured, .initializedSignedIn, .initializedSignedOut, .srpAuthInitiated:
//                XCTAssertEqual(
//                    AuthenticationState.Resolver().resolve(
//                        oldState: oldState,
//                        byApplying: event
//                    ).newState,
//                    oldState
//                )
//            case .error, .signInRequested:
//                // Supported
//                break
//            }
//        }
//
//        AuthenticationEvent.allTestEvents.forEach(assertIfUnsupported(_:))
//    }
//
//}
