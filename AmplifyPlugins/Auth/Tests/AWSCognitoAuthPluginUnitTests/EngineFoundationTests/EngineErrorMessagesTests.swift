//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import InternalAWSCognitoAuth
import XCTest

/// Differential tests: every `EngineErrorMessages` member must return exactly what the
/// `AmplifyErrorMessages` member it copies returns.
class EngineErrorMessagesTests: XCTestCase {

    private struct Location {
        let file: StaticString
        let function: StaticString
        let line: UInt
    }

    private static let locations: [Location] = [
        Location(file: "AWSCognitoAuthPlugin/DeleteUser.swift", function: "execute(_:_:)", line: 57),
        Location(file: "AWSCognitoAuthPlugin/FetchSessionError.swift", function: "authError", line: 80),
        Location(file: "InternalAWSCognitoAuth/AuthorizationError.swift", function: "authError", line: 38),
        Location(file: "AWSPluginsCore/KeychainStoreError.swift", function: "recoverySuggestion", line: 91),
        Location(file: "", function: "", line: 0),
        Location(file: "/an/absolute/path/With Spaces.swift", function: "f(x:y:)", line: UInt.max),
        Location(file: "Ünïcødé/файл.swift", function: "λ()", line: 1)
    ]

    /// - Given: A table of call-site locations
    /// - When: `reportBugToAWS` is called on both types with the same location
    /// - Then: The messages are identical
    ///
    func testReportBugToAWSMatchesAmplify() {
        for location in Self.locations {
            XCTAssertEqual(
                EngineErrorMessages.reportBugToAWS(file: location.file, function: location.function, line: location.line),
                AmplifyErrorMessages.reportBugToAWS(file: location.file, function: location.function, line: location.line),
                "\(location)"
            )
        }
    }

    /// - Given: A table of call-site locations
    /// - When: `shouldNotHappenReportBugToAWS` is called on both types with the same location
    /// - Then: The messages are identical
    ///
    func testShouldNotHappenReportBugToAWSMatchesAmplify() {
        for location in Self.locations {
            XCTAssertEqual(
                EngineErrorMessages.shouldNotHappenReportBugToAWS(
                    file: location.file,
                    function: location.function,
                    line: location.line
                ),
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(
                    file: location.file,
                    function: location.function,
                    line: location.line
                ),
                "\(location)"
            )
        }
    }

    /// - Given: Both types called with their default arguments, from the same line
    /// - When: The messages are compared
    /// - Then: They are identical, so the defaults capture the call site the same way
    ///
    func testDefaultArgumentsCaptureTheCallSiteLikeAmplify() {
        // Each pair is on one line on purpose: the defaults capture `#line`.
        let reportBug = (EngineErrorMessages.reportBugToAWS(), AmplifyErrorMessages.reportBugToAWS())
        let shouldNotHappen = (EngineErrorMessages.shouldNotHappenReportBugToAWS(), AmplifyErrorMessages.shouldNotHappenReportBugToAWS())
        XCTAssertEqual(reportBug.0, reportBug.1)
        XCTAssertEqual(shouldNotHappen.0, shouldNotHappen.1)
        XCTAssertTrue(reportBug.0.contains("function: testDefaultArgumentsCaptureTheCallSiteLikeAmplify()"))
        XCTAssertTrue(reportBug.0.contains("EngineErrorMessagesTests.swift"))
    }

    /// - Given: `shouldNotHappenReportBugToAWSWithoutLineInfo`, which `EngineAuthError.unknown` uses
    /// - When: It is called on both types
    /// - Then: The messages are identical
    ///
    func testShouldNotHappenReportBugToAWSWithoutLineInfoMatchesAmplify() {
        XCTAssertEqual(
            EngineErrorMessages.shouldNotHappenReportBugToAWSWithoutLineInfo(),
            AmplifyErrorMessages.shouldNotHappenReportBugToAWSWithoutLineInfo()
        )
    }
}
