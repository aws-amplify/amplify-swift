//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import XCTest

class DataStoreTestBase: XCTestCase {
    func saveModel<M: Model>(_ model: M) async throws -> M {
        return try await Amplify.DataStore.save(model)
    }

    func queryModel<M: Model>(_ modelType: M.Type, byId id: String) async throws -> M? {
        return try await Amplify.DataStore.query(modelType, byId: id)
    }

    func deleteModel(_ model: some Model) async throws {
        try await Amplify.DataStore.delete(model)
    }
}
