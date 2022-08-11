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
    func saveModel<M: Model>(_ model: M) async -> DataStoreResult<M> {
        let saveFinished = expectation(description: "Save finished")
        var result: DataStoreResult<M>?

        Amplify.DataStore.save(model) { sResult in
            result = sResult
            saveFinished.fulfill()
        }
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        guard let saveResult = result else {
            return .failure(causedBy: "Save operation timed out")
        }
        return saveResult
    }

    func queryModel<M: Model>(_ modelType: M.Type, byId id: String) async -> DataStoreResult<M?> {
        let queryFinished = expectation(description: "Query Finished")
        var result: DataStoreResult<M?>?

        Amplify.DataStore.query(modelType, byId: id) { qResult in
            result = qResult
            queryFinished.fulfill()
        }

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        guard let queryResult = result else {
            return .failure(causedBy: "Query operation timed out")
        }
        return queryResult
    }

    func deleteModel<M: Model>(_ model: M) async -> DataStoreResult<Void> {
        let deleteFinished = expectation(description: "Delete Finished")
        var result: DataStoreResult<Void>?

        Amplify.DataStore.delete(model,
                                 completion: { dResult in
                                    result = dResult
                                    deleteFinished.fulfill()
                                 })

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        guard let deleteResult = result else {
            return .failure(causedBy: "Delete operation timed out")
        }
        return deleteResult
    }
}
