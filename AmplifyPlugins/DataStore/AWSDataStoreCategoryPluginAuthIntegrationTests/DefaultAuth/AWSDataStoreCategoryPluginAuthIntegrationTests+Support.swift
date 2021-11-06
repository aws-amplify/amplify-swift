//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import Amplify

@testable import AmplifyTestCommon

extension AWSDataStoreCategoryPluginAuthIntegrationTests {
    func saveModel(_ id: String = UUID().uuidString, content: String) -> TodoExplicitOwnerField {
        let localTodo = TodoExplicitOwnerField(id: id, content: content, owner: nil)
        var savedTodoOptional: TodoExplicitOwnerField?
        let localTodoSaveInvoked = expectation(description: "local todo was saved")
        Amplify.DataStore.save(localTodo) { result in
            switch result {
            case .success(let todo):
                savedTodoOptional = todo
                localTodoSaveInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to save todo \(error)")
            }
        }
        wait(for: [localTodoSaveInvoked], timeout: TestCommonConstants.networkTimeout)
        guard let savedTodo = savedTodoOptional else {
            fatalError("Could not save todo")
        }
        return savedTodo
    }
}
