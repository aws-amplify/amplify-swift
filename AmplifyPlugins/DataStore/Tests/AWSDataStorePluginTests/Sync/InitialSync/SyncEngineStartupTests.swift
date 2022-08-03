//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

/// Test order of startup operations to ensure SyncEngine is properly following the delta sync merge algorithm
class SyncEngineStartupTests: SyncEngineTestBase {

    func testShouldPauseSubscriptions() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testShouldBufferSubscriptions() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testShouldBufferOutgoingMutations() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testShouldSetUpSubscriptions() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testShouldPerformInitialQueries() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testShouldActivateSubscriptions() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testShouldStartMutations() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testDispatchesToHub() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testOrderOfOperations() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testInvokesGlobalErrorHandler() throws {
        throw XCTSkip("Not yet implemented")
    }

    func testDispatchesToHubOnError() throws {
        throw XCTSkip("Not yet implemented")
    }

}
