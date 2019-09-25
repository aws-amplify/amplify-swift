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

    /// Blocks current thread until the listener with `token` is attached to the plugin. Returns `true` if the listener
    /// becomes present before the `timeout` expires, `false` otherwise.
    ///
    /// - Parameter token: the token identifying the listener to wait for
    /// - Parameter plugin: the plugin on which the listener will be checked
    /// - Parameter timeout: the maximum length of time to wait for the listener to be registered
    /// - Throws: if the plugin cannot be cast to `DefaultHubCategoryPlugin`
    static func waitForListener(with token: UnsubscribeToken,
                                plugin: HubCategoryPlugin,
                                timeout: TimeInterval,
                                file: StaticString = #file,
                                line: UInt = #line) throws -> Bool {

        guard let plugin = plugin as? DefaultHubCategoryPlugin else {
            throw "Could not cast plugin as DefaultHubCategoryPlugin (\(file) L\(line))"
        }

        var hasListener = false

        let deadline = Date(timeIntervalSinceNow: timeout)
        while !hasListener && Date().compare(deadline) == .orderedAscending {
            if plugin.hasListener(withToken: token) {
                hasListener = true
                break
            }
            Thread.sleep(forTimeInterval: 0.01)
        }

        return hasListener
    }

}
