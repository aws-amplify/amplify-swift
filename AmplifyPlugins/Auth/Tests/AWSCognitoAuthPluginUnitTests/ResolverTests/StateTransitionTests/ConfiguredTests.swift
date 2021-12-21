//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

////
////  ConfiguredTests.swift
////
////
////  Created by Schmelter, Tim on 1/6/21.
////
//
//import XCTest
//@testable import AWSCognitoAuthPlugin
//
//class ConfiguredTests: XCTestCase {
//
//    var resolver: AuthenticationState.Resolver {
//        AuthenticationState.Resolver()
//    }
//
//    var oldState = AuthenticationState.configured(.someAsYetUnimplementedAuthType)
//
//    func testInitializedSignedIn() {
//        let expected = AuthenticationState.signedIn(.testData)
//        XCTAssertEqual(
//            resolver.resolve(
//                oldState: oldState,
//                byApplying: AuthenticationEvent.initializedSignedInTest
//            ).newState,
//            expected
//        )
//    }
//
//    func testInitializedSignedOut() {
//        let expected = AuthenticationState.signedOut(.testData, .testData)
//        XCTAssertEqual(
//            resolver.resolve(
//                oldState: oldState,
//                byApplying: AuthenticationEvent.initializedSignedOutTest
//            ).newState,
//            expected
//        )
//    }
//
//    func testError() {
//        let expected = AuthenticationState.error(.testData, .testData)
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
//            case .configured, .signInRequested, .srpAuthInitiated:
//                XCTAssertEqual(
//                    AuthenticationState.Resolver().resolve(
//                        oldState: oldState,
//                        byApplying: event
//                    ).newState,
//                    oldState
//                )
//            case .error, .initializedSignedIn, .initializedSignedOut:
//                // Supported
//                break
//            }
//        }
//
//        AuthenticationEvent.allTestEvents.forEach(assertIfUnsupported(_:))
//    }
//
//}
