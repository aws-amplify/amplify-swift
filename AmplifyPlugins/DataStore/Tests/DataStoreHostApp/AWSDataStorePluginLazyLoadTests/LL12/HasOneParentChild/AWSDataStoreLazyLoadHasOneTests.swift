//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

class AWSDataStoreLazyLoadHasOneTests: AWSDataStoreLazyLoadBaseTest {
    func testStart() async throws {
        await setup(withModels: HasOneModels(), eagerLoad: false, clearOnTearDown: false)
        try await startAndWaitForReady()
    }
}

extension AWSDataStoreLazyLoadHasOneTests {
    
    struct HasOneModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: HasOneChild.self)
            ModelRegistry.register(modelType: HasOneParent.self)
        }
    }
}
