//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class SyncMetadataTests: SyncEngineIntegrationTestBase {

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I sync a new model from the remote API
    /// - Then:
    ///    - The local model is updated with updated remote API information
    func testCreateSyncsRemoteToLocal() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I sync a new model from the remote API
    /// - Then:
    ///    - Local sync metadata (e.g., _version) is updated
    func testCreateUpdatesSyncMetadata() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I sync an updated model from the remote API
    /// - Then:
    ///    - The local model is updated with updated remote API information
    func testUpdateSyncsRemoteToLocal() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I sync an updated model from the remote API
    /// - Then:
    ///    - Local sync metadata (e.g., _version) is updated
    func testUpdateUpdatesSyncMetadata() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I sync a deleted model from the remote API
    /// - Then:
    ///    - The local model is removed from the main table
    func testDeleteSyncsRemoteToLocal() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I sync a deleted model from the remote API
    /// - Then:
    ///    - Local sync metadata (e.g., _version and _deleted) is updated
    func testDeleteUpdatesSyncMetadata() throws {
        XCTFail("Not yet implemented")
    }

}
