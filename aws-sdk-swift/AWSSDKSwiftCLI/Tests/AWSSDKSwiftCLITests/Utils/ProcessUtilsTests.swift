//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import ArgumentParser
import XCTest
import AWSCLIUtils

class ProcessUtilsTests: XCTestCase {

    func test_exit_itThrowsErrorWithErrorCode() {
        let process = Process("false")  // this refers to /usr/bin/false which always returns unsuccessfully
        do {
            try ProcessRunner.standard.run(process)
            XCTFail("Process runner should have thrown")
        } catch let exitCodeError as ExitCode {
            XCTAssertTrue(exitCodeError.rawValue != 0)
        } catch {
            XCTFail("Process runner threw an unexpected type of error")
        }
    }
}
