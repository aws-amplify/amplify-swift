//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class DataStoreTestBase: XCTestCase {

    override func tearDown() {
        Amplify.reset()
        sleep(1)
        super.tearDown()
    }

    func saveModel<M: Model>(_ model: M) -> DataStoreResult<M> {
        let saveFinished = expectation(description: "Save finished")
        var result: DataStoreResult<M>?

        Amplify.DataStore.save(model) { sResult in
            result = sResult
            saveFinished.fulfill()
        }
        wait(for: [saveFinished], timeout: TestCommonConstants.networkTimeout)
        guard let saveResult = result else {
            return .failure(causedBy: "Save operation timed out")
        }
        return saveResult
    }

    func queryModel<M: Model>(_ modelType: M.Type, byId id: String) -> DataStoreResult<M?> {
        let queryFinished = expectation(description: "Query Finished")
        var result: DataStoreResult<M?>?

        Amplify.DataStore.query(modelType, byId: id) { qResult in
            result = qResult
            queryFinished.fulfill()
        }

        wait(for: [queryFinished], timeout: TestCommonConstants.networkTimeout)
        guard let queryResult = result else {
            return .failure(causedBy: "Query operation timed out")
        }
        return queryResult
    }

    func deleteModel<M: Model>(_ model: M) -> DataStoreResult<Void> {
        let deleteFinished = expectation(description: "Delete Finished")
        var result: DataStoreResult<Void>?

        Amplify.DataStore.delete(model,
                                 completion: { dResult in
                                    result = dResult
                                    deleteFinished.fulfill()
                                 })

        wait(for: [deleteFinished], timeout: TestCommonConstants.networkTimeout)
        guard let deleteResult = result else {
            return .failure(causedBy: "Delete operation timed out")
        }
        return deleteResult
    }

}
