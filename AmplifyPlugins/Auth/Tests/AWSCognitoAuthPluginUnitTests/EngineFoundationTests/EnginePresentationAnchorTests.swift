//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth
import XCTest

/// Tests for the engine's presentation anchor alias.
class EnginePresentationAnchorTests: XCTestCase {

    /// - Given: The engine's anchor alias
    /// - When: It is compared with the name the plugin and Amplify use
    /// - Then: It is the same type, so anchors cross the plugin boundary unconverted
    ///
    func testEnginePresentationAnchorIsTheAuthUIPresentationAnchor() {
        XCTAssertTrue(EnginePresentationAnchor.self == AuthUIPresentationAnchor.self)
        #if os(iOS) || os(macOS) || os(visionOS)
        XCTAssertTrue(EnginePresentationAnchor.self == ASPresentationAnchor.self)
        #else
        XCTAssertTrue(EnginePresentationAnchor.self == AuthUIPresentationAnchorPlaceholder.self)
        #endif
    }
}
