//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class SyncMetadataTests: SyncEngineIntegrationTestBase {

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I sync a new model from the remote API
    /// - Then:
    ///    - The local model is updated with updated remote API information
    func testCreateSyncsCloudToLocal() throws {
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
    func testUpdateSyncsCloudToLocal() throws {
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

}
