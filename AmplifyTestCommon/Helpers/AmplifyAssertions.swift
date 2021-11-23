//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import CwlPreconditionTesting

public func XCTAssertThrowFatalError(_ expression: @escaping () -> Void,
                                     file: StaticString = #file,
                                     line: UInt = #line) throws {
#if (os(iOS) || os(macOS)) && (arch(arm64) || arch(x86_64))
    var reached = false
    let exception = catchBadInstruction {
        expression()
        reached = true
    }
    XCTAssertNotNil(exception, "No fatal error thrown", file: file, line: line)
    XCTAssertFalse(reached, "Code executed past expected fatal error", file: file, line: line)
#else
    throw XCTSkip("XCTAssertThrowFatalError is only available on iOS and macOS for x86_64 and arm64 architectures.")
#endif
}

public func XCTAssertNoThrowFatalError(_ expression: @escaping () -> Void,
                                       file: StaticString = #file,
                                       line: UInt = #line) throws {
#if (os(iOS) || os(macOS)) && (arch(arm64) || arch(x86_64))
    var reached = false
    let exception = catchBadInstruction {
        expression()
        reached = true
    }
    XCTAssertNil(exception, "Fatal error thrown", file: file, line: line)
    XCTAssertTrue(reached, "Code did not execute past expected fatal error", file: file, line: line)
#else
    throw XCTSkip("XCTAssertNoThrowFatalError is only available on iOS and macOS for x86_64 and arm64 architectures.")
#endif
}
