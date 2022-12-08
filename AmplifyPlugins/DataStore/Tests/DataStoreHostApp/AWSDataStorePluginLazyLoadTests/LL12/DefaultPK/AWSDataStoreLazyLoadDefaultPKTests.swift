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

class AWSDataStoreLazyLoadDefaultPKTests: AWSDataStoreLazyLoadBaseTest {
    func testStart() async throws {
        await setup(withModels: DefaultPKModels(), eagerLoad: false, clearOnTearDown: false)
        try await startAndWaitForReady()
    }
}

extension AWSDataStoreLazyLoadDefaultPKTests {
    
    struct DefaultPKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: DefaultPKChild.self)
            ModelRegistry.register(modelType: DefaultPKParent.self)
        }
    }
}
