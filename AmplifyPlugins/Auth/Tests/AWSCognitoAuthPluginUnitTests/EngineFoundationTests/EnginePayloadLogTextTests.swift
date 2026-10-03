//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// The log-transcript gate for the engine's payload forks: verbose log lines that interpolate a sign-in step or a
/// sign-up result (for example `UserPoolSignInHelper`'s "Checking next step for:" and the challenge
/// actions' "Sending event") must read as before once the transcript normaliser maps the fork names back.
/// The golden transcript has no challenge or sign-up scenario, so this checks the printed payloads directly.
class EnginePayloadLogTextTests: XCTestCase {

    /// Test that every printed sign-in step normalises to the public step's text
    ///
    /// - Given: The exhaustive step table, without two kinds of value:
    ///    - sets of two or more elements: two different `Set` types iterate in different orders, as the same
    ///      set did from run to run;
    ///    - delivery details with an attribute: the fork prints the wire name (`Optional("email")`) where the
    ///      public type printed the key (`Optional(Amplify.AuthUserAttributeKey.email)`). The engine never
    ///      builds a sign-in step with one: `RespondToAuthChallenge.codeDeliveryDetails` always passes `nil`
    /// - When:
    ///    - Each public step and its engine conversion are interpolated into a string
    /// - Then:
    ///    - The engine text, normalised with `scripts/m2/rename_table.json`, equals the public text
    ///
    func testPrintedSignInStepsNormaliseToThePublicText() throws {
        let normaliser = try LogTranscriptNormaliser.fromRepository()
        var compared = Set<String>()
        for step in EnginePayloadForkTests.signInSteps where !hasMultiElementSet(step) && !hasAttribute(step) {
            let engine = EngineSignInStep(step)
            XCTAssertEqual(normaliser.normaliseText("\(engine)"), normaliser.normaliseText("\(step)"))
            compared.insert(String("\(step)".prefix { $0 != "(" }))
        }
        XCTAssertEqual(compared.count, 14, "every case is compared at least once")
    }

    /// Test that printed sign-up results and delivery details normalise to the public text
    ///
    /// - Given: Sign-up results for every step, and delivery details for every destination with and without
    ///   an attribute
    /// - When:
    ///    - Each public value and its engine conversion are interpolated into a string
    /// - Then:
    ///    - The engine text, normalised, equals the public text
    ///
    func testPrintedSignUpResultsAndDeliveryDetailsNormaliseToThePublicText() throws {
        let normaliser = try LogTranscriptNormaliser.fromRepository()
        let details: [AuthCodeDeliveryDetails?] = [nil, .init(destination: .email("a@example.com"))]
        let steps: [AuthSignUpStep] = [.done, .completeAutoSignIn("session")]
            + details.map { .confirmUser($0, ["key": "value"], "sub") }
        for step in steps {
            let result = AuthSignUpResult(step, userID: "sub")
            XCTAssertEqual(
                normaliser.normaliseText("\(EngineSignUpResult(result))"),
                normaliser.normaliseText("\(result)")
            )
        }
        for destination in EnginePayloadForkTests.destinations {
            let details = AuthCodeDeliveryDetails(destination: destination, attributeKey: nil)
            XCTAssertEqual(
                normaliser.normaliseText("\(EngineCodeDeliveryDetails(details))"),
                normaliser.normaliseText("\(details)")
            )
        }
    }

    private func hasAttribute(_ step: AuthSignInStep) -> Bool {
        switch step {
        case .confirmSignInWithSMSMFACode(let details, _), .confirmSignInWithOTP(let details):
            return details.attributeKey != nil
        default:
            return false
        }
    }

    private func hasMultiElementSet(_ step: AuthSignInStep) -> Bool {
        switch step {
        case .continueSignInWithMFASelection(let types), .continueSignInWithMFASetupSelection(let types):
            return types.count > 1
        case .continueSignInWithFirstFactorSelection(let factors):
            return factors.count > 1
        default:
            return false
        }
    }
}
