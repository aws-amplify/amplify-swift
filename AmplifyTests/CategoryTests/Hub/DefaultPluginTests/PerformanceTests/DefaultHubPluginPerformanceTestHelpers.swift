//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

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

    // swiftlint:disable function_parameter_count
    static func makeTestObjectsForDispatcherTypes<T: Dispatcher>(listenerCount: Int,
                                                                 listenerChannels: [HubChannel],
                                                                 dispatcherType: T.Type,
                                                                 dispatcherChannels: [HubChannel],
                                                                 expectedChannels: [HubChannel],
                                                                 testCase: XCTestCase) -> PerformanceTestObjects {
        // swiftlint:enable function_parameter_count

        var dispatchers = [Dispatcher]()
        for channel in dispatcherChannels {
            let dispatcher: Dispatcher
            switch dispatcherType {
            case is ConcurrentDispatcher.Type:
                dispatcher = ConcurrentDispatcher(channel: channel,
                                                  payload: HubPayload(event: "TEST_EVENT"))
            case is SerialDispatcher.Type:
                dispatcher = SerialDispatcher(channel: channel,
                                              payload: HubPayload(event: "TEST_EVENT"))
            default:
                fatalError("Unknown dispatcher type: \(dispatcherType)")
            }
            dispatchers.append(dispatcher)
        }

        let (listeners, expectations) =
            DefaultHubPluginTestHelpers.makeListeners(count: listenerCount,
                                                      for: listenerChannels,
                                                      expectedChannels: expectedChannels,
                                                      testCase: testCase)

        let objects = PerformanceTestObjects(dispatchers: dispatchers,
                                             listeners: listeners,
                                             expectations: expectations)

        return objects
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
