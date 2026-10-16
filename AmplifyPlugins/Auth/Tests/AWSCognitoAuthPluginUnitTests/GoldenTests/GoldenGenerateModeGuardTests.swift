//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

/// Fails any run of the whole suite with a golden generate switch set.
///
/// With `AMPLIFY_GENERATE_GOLDEN=1` the golden tests write their files instead of comparing them, and pass;
/// with `AMPLIFY_GOLDEN_OVERWRITE_FROZEN=1` they also overwrite the frozen baselines. The switches are read
/// from the test process's environment, which a CI file can reach in more than one way (the scheme's launch
/// environment, `TEST_RUNNER_<NAME>` for xcodebuild, or the shell for `swift test`). CI runs the whole
/// scheme, so this test runs there and turns such a run red, whichever way the switch got in.
///
/// The documented regeneration commands (`swift test --filter <suite>`) select one golden suite and leave
/// this test out.
final class GoldenGenerateModeGuardTests: XCTestCase {

    /// The golden generate switches are never set in a run that includes every test.
    ///
    /// - Given: The test process's environment
    /// - When:
    ///    - It is checked for `AMPLIFY_GENERATE_GOLDEN=1` and `AMPLIFY_GOLDEN_OVERWRITE_FROZEN=1`
    /// - Then:
    ///    - Neither is `1`, the value the golden tests act on, so every golden test compared its files
    ///      instead of writing them
    ///
    func testGoldenGenerateSwitchesAreNotSet() {
        let environment = ProcessInfo.processInfo.environment
        for key in [GoldenFiles.generateEnvironmentKey, "AMPLIFY_GOLDEN_OVERWRITE_FROZEN"] {
            XCTAssertNotEqual(
                environment[key],
                "1",
                """
                \(key)=1 is set, so the golden tests wrote their files instead of comparing them. Regenerate \
                with `swift test --filter <suite>`, then rerun without \(key) to compare.
                """
            )
        }
    }
}
