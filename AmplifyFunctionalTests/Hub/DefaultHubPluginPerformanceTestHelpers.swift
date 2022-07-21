//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

struct DefaultHubPluginPerformanceTestHelpers {

    static func makeTestObjectsForSingleChannel<T: Dispatcher>(listenerCount: Int,
                                                               dispatcherType: T.Type,
                                                               testCase: XCTestCase) -> PerformanceTestObjects {
        let dispatcherChannels = [HubChannel.storage]

        let listenerChannels = [HubChannel.storage]

        let expectedChannels = [HubChannel.storage]

        return makeTestObjectsForDispatcherTypes(listenerCount: listenerCount,
                                                 listenerChannels: listenerChannels,
                                                 dispatcherType: dispatcherType,
                                                 dispatcherChannels: dispatcherChannels,
                                                 expectedChannels: expectedChannels,
                                                 testCase: testCase)
    }

    static func makeTestObjectsForSingleDispatcher<T: Dispatcher>(listenerCount: Int,
                                                                  dispatcherType: T.Type,
                                                                  testCase: XCTestCase) -> PerformanceTestObjects {
        let dispatcherChannels = [HubChannel.storage]

        let listenerChannels = [HubChannel.storage,
                                .custom("CustomChannel1"),
                                .custom("CustomChannel2"),
                                .custom("CustomChannel3"),
                                .custom("CustomChannel4")]

        let expectedChannels = [HubChannel.storage]

        return makeTestObjectsForDispatcherTypes(listenerCount: listenerCount,
                                                 listenerChannels: listenerChannels,
                                                 dispatcherType: dispatcherType,
                                                 dispatcherChannels: dispatcherChannels,
                                                 expectedChannels: expectedChannels,
                                                 testCase: testCase)
    }

    static func makeTestObjectsForMultipleDispatchers<T: Dispatcher>(listenerCount: Int,
                                                                     dispatcherType: T.Type,
                                                                     testCase: XCTestCase) -> PerformanceTestObjects {
        let dispatcherChannels = [HubChannel.storage, .custom("CustomChannel1")]

        let listenerChannels = [HubChannel.storage,
                                .custom("CustomChannel1"),
                                .custom("CustomChannel2"),
                                .custom("CustomChannel3"),
                                .custom("CustomChannel4")]

        let expectedChannels = [HubChannel.storage, .custom("CustomChannel1")]

        return makeTestObjectsForDispatcherTypes(listenerCount: listenerCount,
                                                 listenerChannels: listenerChannels,
                                                 dispatcherType: dispatcherType,
                                                 dispatcherChannels: dispatcherChannels,
                                                 expectedChannels: expectedChannels,
                                                 testCase: testCase)
    }

    // swiftlint:disable:next function_parameter_count
    static func makeTestObjectsForDispatcherTypes<T: Dispatcher>(listenerCount: Int,
                                                                 listenerChannels: [HubChannel],
                                                                 dispatcherType: T.Type,
                                                                 dispatcherChannels: [HubChannel],
                                                                 expectedChannels: [HubChannel],
                                                                 testCase: XCTestCase) -> PerformanceTestObjects {

        var dispatchers = [Dispatcher]()
        for channel in dispatcherChannels {
            let dispatcher: Dispatcher
            switch dispatcherType {
            case is ConcurrentDispatcher.Type:
                dispatcher = ConcurrentDispatcher(channel: channel,
                                                  payload: HubPayload(eventName: "TEST_EVENT"))
            case is SerialDispatcher.Type:
                dispatcher = SerialDispatcher(channel: channel,
                                              payload: HubPayload(eventName: "TEST_EVENT"))
            default:
                fatalError("Unknown dispatcher type: \(dispatcherType)")
            }
            dispatchers.append(dispatcher)
        }

        let (listeners, expectations) = makeListeners(count: listenerCount,
                                                      for: listenerChannels,
                                                      expectedChannels: expectedChannels,
                                                      testCase: testCase)

        let objects = PerformanceTestObjects(dispatchers: dispatchers,
                                             listeners: listeners,
                                             expectations: expectations)

        return objects
    }

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

enum DispatcherType {
    case concurrent, serial
}

struct PerformanceTestObjects {
    let dispatchers: [Dispatcher]
    let listeners: [FilteredListener]
    let expectations: [XCTestExpectation]
}
