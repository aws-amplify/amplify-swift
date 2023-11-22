//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DataStoreConnectionScenario1Tests {
    
    #if os(watchOS)
    func testStartAndSync() async throws {
        await setUp(withModels: TestModelRegistration(),
                    dataStoreConfiguration: .custom(syncMaxRecords: 100, disableSubscriptions: { true }))
        try await startAmplifyAndWaitForSync()
    }

    func testSaveReconciled() async throws {
        await setUp(withModels: TestModelRegistration(),
                    dataStoreConfiguration: .custom(syncMaxRecords: 100, disableSubscriptions: { true }))
        try await startAmplifyAndWaitForSync()
        
        let team = Team1(name: "name1")
        let project = Project1(team: team)
        let syncedTeamReceived = expectation(description: "received team from sync path")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedTeam = try? mutationEvent.decodeModel() as? Team1,
               syncedTeam == team {
                syncedTeamReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.save(team)
        await fulfillment(of: [syncedTeamReceived], timeout: networkTimeout)
        
        let syncProjectReceived = expectation(description: "received project from sync path")
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedProject = try? mutationEvent.decodeModel() as? Project1,
                      syncedProject == project {
                syncProjectReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(project)
        await fulfillment(of: [syncProjectReceived], timeout: networkTimeout)

        let queriedProjectOptional = try await Amplify.DataStore.query(Project1.self, byId: project.id)
        guard let queriedProject = queriedProjectOptional else {
            XCTFail("Failed")
            return
        }
        XCTAssertEqual(queriedProject.id, project.id)
        XCTAssertEqual(queriedProject.team, team)
    }
    #endif
    
}
