//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

// Removing this test case since it's not actually used in the default hub plugin. Leaving the commented case in place
// in case we want to re-enable to test specific use cases.
// swiftlint:disable comment_spacing
//class ConcurrentDispatcherPerformanceTests: XCTestCase {
//
//    let dispatcherTypeUnderTest = ConcurrentDispatcher.self
//
//    override func setUp() {
//        Amplify.reset()
//        let config = AmplifyConfiguration()
//        do {
//            try Amplify.configure(config)
//        } catch {
//            XCTFail("Error setting up Amplify: \(error)")
//        }
//    }
//
//    override func tearDown() {
//        Amplify.reset()
//    }
//
//    // MARK: - Performance of single channel, multiple listeners
//
//    func testSingleChannel_10() {
//        let listenerCount = 10
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForSingleChannel(listenerCount: listenerCount,
//                                                 dispatcherType: dispatcherTypeUnderTest,
//                                                 testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testSingleChannel_100() {
//        let listenerCount = 100
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForSingleChannel(listenerCount: listenerCount,
//                                                 dispatcherType: dispatcherTypeUnderTest,
//                                                 testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testSingleChannel_1_000() {
//        let listenerCount = 1_000
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForSingleChannel(listenerCount: listenerCount,
//                                                 dispatcherType: dispatcherTypeUnderTest,
//                                                 testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testSingleChannel_10_000() {
//        let listenerCount = 10_000
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForSingleChannel(listenerCount: listenerCount,
//                                                 dispatcherType: dispatcherTypeUnderTest,
//                                                 testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    // MARK: - Performance of multiple channels, multiple listeners
//
//    func testMultipleChannel_10() {
//        let listenerCount = 10
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForSingleDispatcher(listenerCount: listenerCount,
//                                                    dispatcherType: dispatcherTypeUnderTest,
//                                                    testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testMultipleChannel_100() {
//        let listenerCount = 100
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForSingleDispatcher(listenerCount: listenerCount,
//                                                    dispatcherType: dispatcherTypeUnderTest,
//                                                    testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testMultipleChannel_1_000() {
//        let listenerCount = 1_000
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForSingleDispatcher(listenerCount: listenerCount,
//                                                    dispatcherType: dispatcherTypeUnderTest,
//                                                    testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testMultipleChannel_10_000() {
//        let listenerCount = 10_000
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForSingleDispatcher(listenerCount: listenerCount,
//                                                    dispatcherType: dispatcherTypeUnderTest,
//                                                    testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    // MARK: - Performance of multiple dispatchers, multiple channels, multiple listeners
//
//    func testMultipleDispatchers_10() {
//        let listenerCount = 10
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForMultipleDispatchers(listenerCount: listenerCount,
//                                                       dispatcherType: dispatcherTypeUnderTest,
//                                                       testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testMultipleDispatchers_100() {
//        let listenerCount = 100
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForMultipleDispatchers(listenerCount: listenerCount,
//                                                       dispatcherType: dispatcherTypeUnderTest,
//                                                       testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testMultipleDispatchers_1_000() {
//        let listenerCount = 1_000
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForMultipleDispatchers(listenerCount: listenerCount,
//                                                       dispatcherType: dispatcherTypeUnderTest,
//                                                       testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//    func testMultipleDispatchers_10_000() {
//        let listenerCount = 10_000
//        measure {
//            let testObjects = DefaultHubPluginPerformanceTestHelpers
//                .makeTestObjectsForMultipleDispatchers(listenerCount: listenerCount,
//                                                       dispatcherType: dispatcherTypeUnderTest,
//                                                       testCase: self)
//
//            for dispatcher in testObjects.dispatchers {
//                dispatcher.dispatch(to: testObjects.listeners)
//            }
//            wait(for: testObjects.expectations, timeout: 30.0)
//        }
//    }
//
//}
// swiftlint:enable comment_spacing
