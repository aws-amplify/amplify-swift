//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

////
////  UnconfiguredTests.swift
////
////
////  Created by Schmelter, Tim on 1/6/21.
////
//
//import XCTest
//
//@testable import AWSCognitoAuthPlugin
//
//class UnconfiguredTests: XCTestCase {
//
//    var resolver: AuthenticationState.Resolver {
//        AuthenticationState.Resolver()
//    }
//
//    var oldState = AuthenticationState.unconfigured
//
//    func testConfigure() {
//        let expected = AuthenticationState.configured(.someAsYetUnimplementedAuthType)
//        XCTAssertEqual(
//            resolver.resolve(
//                oldState: oldState,
//                byApplying: AuthenticationEvent.configuredTest
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
//            case .initializedSignedIn, .initializedSignedOut, .signInRequested, .srpAuthInitiated:
//                XCTAssertEqual(
//                    AuthenticationState.Resolver().resolve(
//                        oldState: oldState,
//                        byApplying: event
//                    ).newState,
//                    oldState
//                )
//            case .configured,
//                 .error:
//                // Supported
//                break
//            }
//        }
//
//        AuthenticationEvent.allTestEvents.forEach(assertIfUnsupported(_:))
//    }
//
//}
