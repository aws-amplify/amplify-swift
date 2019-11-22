//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

struct DefaultHubPluginTestHelpers {

    /// Makes `count` listeners for each channel in `channels`
    ///
    /// - Parameter count: The number of listeners to make for each channel
    /// - Parameter channels: The channels for which to make listeners
    /// - Parameter expectedChannels: The channels for which to create expectations
    /// - Parameter testcase: The XCTestCase for which to create expectations
    static func makeListeners(count: Int,
                              for channels: [HubChannel],
                              expectedChannels: [HubChannel],
                              testCase: XCTestCase) -> ([FilteredListener], [XCTestExpectation]) {
        var listeners = [FilteredListener]()
        var expectations = [XCTestExpectation]()

        for idx in 0 ..< count {
            for channel in channels {
                var expectation: XCTestExpectation?
                if expectedChannels.contains(channel) {
                    expectation = testCase.expectation(description: "Listener \(idx) invoked for channel \(channel)")
                    expectations.append(expectation!)
                }
                let listener = FilteredListener(for: channel, filter: nil) { _ in expectation?.fulfill() }
                listeners.append(listener)
            }
        }

        return (listeners, expectations)
    }

}
