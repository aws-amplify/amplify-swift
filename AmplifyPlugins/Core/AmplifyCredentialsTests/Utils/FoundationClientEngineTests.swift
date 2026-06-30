//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(FoundationClientEngine)
@testable import InternalAmplifyCredentials
import XCTest

class FoundationClientEngineTests: XCTestCase {

    /// Given: A `FoundationClientEngine`.
    /// When: The engine is initialized.
    /// Then: Its `URLSession` has URL caching disabled so that responses
    ///       carrying Cognito tokens / AWS credentials are never persisted
    ///       to disk (e.g. Cache.db).
    func test_urlSession_disablesCaching() {
        let engine = FoundationClientEngine()
        let configuration = engine.urlSession.configuration

        XCTAssertNil(
            configuration.urlCache,
            "URLSession must not have a URLCache, otherwise credential responses are persisted to disk."
        )
        XCTAssertEqual(
            configuration.requestCachePolicy,
            .reloadIgnoringLocalCacheData
        )
    }
}
