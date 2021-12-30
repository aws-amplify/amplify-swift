//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSDataStorePlugin

class StopwatchTests: XCTestCase {

    func testStartLapStop() throws {
        let stopwatch = Stopwatch()
        XCTAssertNil(stopwatch.startTime)
        XCTAssertNil(stopwatch.lapStart)

        stopwatch.start()
        XCTAssertNotNil(stopwatch.startTime)
        XCTAssertNotNil(stopwatch.lapStart)

        let lap1 = stopwatch.lap()
        XCTAssertTrue(lap1 > 0)

        let lap2 = stopwatch.lap()
        XCTAssertTrue(lap2 > 0)

        let total = stopwatch.stop()
        XCTAssertTrue(total > 0)
        let totalLap = lap1 + lap2
        XCTAssertTrue(total > totalLap)

        XCTAssertNil(stopwatch.startTime)
        XCTAssertNil(stopwatch.lapStart)
    }

    func testConcurrentLap() {
        let stopwatch = Stopwatch()
        stopwatch.start()
        DispatchQueue.concurrentPerform(iterations: 1_000) { _ in
            let lap1 = stopwatch.lap()
            XCTAssertTrue(lap1 > 0)
            let lap2 = stopwatch.lap()
            XCTAssertTrue(lap2 > 0)
        }
    }
}
