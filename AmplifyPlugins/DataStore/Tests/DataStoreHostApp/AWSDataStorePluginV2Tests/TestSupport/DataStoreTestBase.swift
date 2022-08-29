//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Amplify

class DataStoreTestBase: XCTestCase {
    func saveModel<M: Model>(_ model: M) async throws -> M {
        return try await Amplify.DataStore.save(model)
    }

    func queryModel<M: Model>(_ modelType: M.Type, byId id: String) async throws -> M? {
        return try await Amplify.DataStore.query(modelType, byId: id)
    }

    func deleteModel<M: Model>(_ model: M) async throws {
        try await Amplify.DataStore.delete(model)
    }
}
