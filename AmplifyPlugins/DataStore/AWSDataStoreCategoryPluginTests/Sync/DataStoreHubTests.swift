//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

class DataStoreHubTests: XCTestCase {

    /// - Given: An API-enabled DataStore
    /// - When:
    ///    - DataStore receives a subscription message that resolves to a create
    /// - Then:
    ///    - Hub is notified
    ///    - Hub payload accurately represents the incoming sync
    func testDataStoreDispatchesCreateToHub() throws {
        throw XCTSkip("Not yet implemented")
    }

    /// - Given: An API-enabled DataStore
    /// - When:
    ///    - DataStore receives a subscription message that resolves to an update
    /// - Then:
    ///    - Hub is notified
    ///    - Hub payload accurately represents the incoming sync
    func testDataStoreDispatchesUpdateToHub() throws {
        throw XCTSkip("Not yet implemented")
    }

    /// - Given: An API-enabled DataStore
    /// - When:
    ///    - DataStore receives a subscription message that resolves to a delete
    /// - Then:
    ///    - Hub is notified
    ///    - Hub payload accurately represents the incoming sync
    func testDataStoreDispatchesDeleteToHub() throws {
        throw XCTSkip("Not yet implemented")
    }

    /// - Given: An API-enabled DataStore
    /// - When:
    ///    - DataStore receives a subscription message that resolves to a conflict
    /// - Then:
    ///    - Hub is notified
    ///    - Hub payload accurately represents the incoming sync
    func testDataStoreDispatchesConflictToHub() throws {
        // TODO: Can this actually happen on an incoming sync?
        throw XCTSkip("Not yet implemented")
    }

    /// - Given: An API-enabled DataStore
    /// - When:
    ///    - DataStore encounters a sync error
    /// - Then:
    ///    - Hub is notified
    func testDataStoreDispatchesErrorToHub() throws {
        throw XCTSkip("Not yet implemented")
    }

}
