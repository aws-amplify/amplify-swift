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
    func saveNote(_ id: String = UUID().uuidString, content: String) -> SocialNote {
        let localNote = SocialNote(id: id, content: content, owner: nil)
        var savedNoteOptional: SocialNote?
        let localNoteSaveInvoked = expectation(description: "local note was saved")
        Amplify.DataStore.save(localNote) { result in
            switch result {
            case .success(let note):
                savedNoteOptional = note
                localNoteSaveInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to save note \(error)")
            }
        }
        wait(for: [localNoteSaveInvoked], timeout: TestCommonConstants.networkTimeout)
        guard let savedNote = savedNoteOptional else {
            fatalError("Could not save note")
        }
        return savedNote
    }

    func queryNote(byId id: String) -> SocialNote? {
        var queriedNoteOptional: SocialNote?
        let localNoteQueriedInvoked = expectation(description: "note was queried")
        Amplify.DataStore.query(SocialNote.self, byId: id) { result in
            switch result {
            case .success(let socialNoteOptional):
                queriedNoteOptional = socialNoteOptional
                localNoteQueriedInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to query note \(error)")
            }
        }
        wait(for: [localNoteQueriedInvoked], timeout: TestCommonConstants.networkTimeout)
        return queriedNoteOptional
    }
}
