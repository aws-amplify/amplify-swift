//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@testable import InternalAmplifyKeychain

final class VerboseOnlyLoggerTests: XCTestCase {

    /// Every message reaches the base logger at verbose level, and none at any other level.
    ///
    /// - Given: a verbose-only logger over a recording logger
    /// - When: a message is logged at every level, directly and through `log(_:_:_:)`
    /// - Then:
    ///    - all of them arrive at verbose level, except `.none`, which is dropped
    func testEveryLevelIsLoggedAtVerbose() {
        let base = RecordingLogger()
        let logger = VerboseOnlyLogger(base)

        logger.error("error", nil)
        logger.warn("warn", nil)
        logger.info("info", nil)
        logger.debug("debug", nil)
        logger.verbose("verbose", nil)
        logger.log(.error, "logged error", nil)
        logger.log(.none, "dropped", nil)

        XCTAssertEqual(base.messages(at: .verbose), ["error", "warn", "info", "debug", "verbose", "logged error"])
        for level in [LogLevel.error, .warn, .info, .debug] {
            XCTAssertEqual(base.messages(at: level), [], "\(level)")
        }
    }
}
