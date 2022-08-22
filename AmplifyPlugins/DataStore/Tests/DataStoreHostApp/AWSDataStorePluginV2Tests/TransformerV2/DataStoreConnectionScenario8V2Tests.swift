//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin

/*

 ```
 # 13 Multiple hasOne-hasMany relationships on same type

 type Meeting8V2 @model {
   id: ID!
   title: String!
   attendees: [Registration8V2] @hasMany(indexName: "byMeeting", fields: ["id"])
 }

 type Attendee8V2 @model {
   id: ID!
   meetings: [Registration8V2] @hasMany(indexName: "byAttendee", fields: ["id"])
 }

 type Registration8V2 @model {
   id: ID!
   meetingId: ID @index(name: "byMeeting", sortKeyFields: ["attendeeId"])
   meeting: Meeting8V2! @belongsTo(fields: ["meetingId"])
   attendeeId: ID @index(name: "byAttendee", sortKeyFields: ["meetingId"])
   attendee: Attendee8V2! @belongsTo(fields: ["attendeeId"])
 }
 ```
 */
// swiftlint:disable type_body_length
class DataStoreConnectionScenario8V2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Meeting8V2.self)
            registry.register(modelType: Attendee8V2.self)
            registry.register(modelType: Registration8V2.self)
        }

        let version: String = "1"
    }

    func testSaveRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let attendee = saveAttendee(),
              let meeting = saveMeeting(),
              let registration = saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let attendeeEvent = try? mutationEvent.decodeModel() as? Attendee8V2,
                    attendeeEvent.id == attendee.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let meetingEvent = try? mutationEvent.decodeModel() as? Meeting8V2, meetingEvent.id == meeting.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(meetingEvent.title, meeting.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                    registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)
        let getAttendeeCompleted = expectation(description: "get attendee completed")
        Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id) { result in
            switch result {
            case .success(let queriedAttendeeOptional):
                guard let queriedAttendee = queriedAttendeeOptional else {
                    XCTFail("Could not get attendee")
                    return
                }
                XCTAssertEqual(queriedAttendee.meetings?.count, 1)
                getAttendeeCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getAttendeeCompleted], timeout: TestCommonConstants.networkTimeout)
        let getMeetingCompleted = expectation(description: "get meeting completed")
        Amplify.DataStore.query(Meeting8V2.self, byId: meeting.id) { result in
            switch result {
            case .success(let queriedMeetingOptional):
                guard let queriedMeeting = queriedMeetingOptional else {
                    XCTFail("Could not get meeting")
                    return
                }
                XCTAssertEqual(queriedMeeting.attendees?.count, 1)
                getMeetingCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getMeetingCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testUpdateRegistrationToAnotherAttendee() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let attendee = saveAttendee(),
              let attendee2 = saveAttendee(),
              let meeting = saveMeeting(),
              var registration = saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
                  return
              }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 4 // 4 models (2 attendees and 1 meeting and 1 registration)
        let updateReceived = expectation(description: "Update notification received")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                else {
                    XCTFail("Can't cast payload as mutation event")
                    return
                }
                if let attendeeEvent = try? mutationEvent.decodeModel() as? Attendee8V2,
                   attendeeEvent.id == attendee.id || attendeeEvent.id == attendee2.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }

                }

                if let meetingEvent = try? mutationEvent.decodeModel() as? Meeting8V2, meetingEvent.id == meeting.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(meetingEvent.title, meeting.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                   registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    } else if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        updateReceived.fulfill()
                        return
                    }
                }
            }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let updateRegistrationCompleted = expectation(description: "update registration completed")
        registration.attendee = attendee2
        Amplify.DataStore.save(registration) { result in
            switch result {
            case .success(let updatedRegistration):
                XCTAssertEqual(updatedRegistration.attendee.id, attendee2.id)
                updateRegistrationCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [updateRegistrationCompleted, updateReceived], timeout: TestCommonConstants.networkTimeout)

        let getAttendeesCompleted = expectation(description: "get attendees completed")
        getAttendeesCompleted.expectedFulfillmentCount = 2
        Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id) { result in
            switch result {
            case .success(let queriedAttendeeOptional):
                guard let queriedAttendee = queriedAttendeeOptional else {
                    XCTFail("Could not get attendee")
                    return
                }
                XCTAssertEqual(queriedAttendee.meetings?.count, 0)
                getAttendeesCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        Amplify.DataStore.query(Attendee8V2.self, byId: attendee2.id) { result in
            switch result {
            case .success(let queriedAttendeeOptional):
                guard let queriedAttendee = queriedAttendeeOptional else {
                    XCTFail("Could not get attendee")
                    return
                }
                XCTAssertEqual(queriedAttendee.meetings?.count, 1)
                getAttendeesCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getAttendeesCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let attendee = saveAttendee(),
              let meeting = saveMeeting(),
              let registration = saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        let deleteRegistrationRecieved = expectation(description: "Delete registration received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let attendeeEvent = try? mutationEvent.decodeModel() as? Attendee8V2,
                    attendeeEvent.id == attendee.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let meetingEvent = try? mutationEvent.decodeModel() as? Meeting8V2, meetingEvent.id == meeting.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(meetingEvent.title, meeting.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                    registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteRegistrationRecieved.fulfill()
                    }
                }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)
        let deleteCompleted = expectation(description: "delete completed")
        Amplify.DataStore.delete(Registration8V2.self, withId: registration.id) { result in
            switch result {
            case .success:
                deleteCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [deleteCompleted, deleteRegistrationRecieved], timeout: TestCommonConstants.networkTimeout)
        let getAttendeeCompleted = expectation(description: "get attendee completed")
        Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id) { result in
            switch result {
            case .success(let queriedAttendeeOptional):
                guard let queriedAttendee = queriedAttendeeOptional else {
                    XCTFail("Could not get attendee")
                    return
                }
                XCTAssertEqual(queriedAttendee.meetings?.count, 0)
                getAttendeeCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getAttendeeCompleted], timeout: TestCommonConstants.networkTimeout)
        let getMeetingCompleted = expectation(description: "get meeting completed")
        Amplify.DataStore.query(Meeting8V2.self, byId: meeting.id) { result in
            switch result {
            case .success(let queriedMeetingOptional):
                guard let queriedMeeting = queriedMeetingOptional else {
                    XCTFail("Could not get meeting")
                    return
                }
                XCTAssertEqual(queriedMeeting.attendees?.count, 0)
                getMeetingCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getMeetingCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAttendeeShouldCascadeDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let attendee = saveAttendee(),
              let meeting = saveMeeting(),
              let registration = saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        let deleteReceived = expectation(description: "Delete received")
        deleteReceived.expectedFulfillmentCount = 2 // attendee and registration
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let attendeeEvent = try? mutationEvent.decodeModel() as? Attendee8V2,
                    attendeeEvent.id == attendee.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                        return
                    }
                }
                if let meetingEvent = try? mutationEvent.decodeModel() as? Meeting8V2, meetingEvent.id == meeting.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(meetingEvent.title, meeting.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                    registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)
        let deleteCompleted = expectation(description: "delete completed")
        Amplify.DataStore.delete(Attendee8V2.self, withId: attendee.id) { result in
            switch result {
            case .success:
                deleteCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [deleteCompleted, deleteReceived], timeout: TestCommonConstants.networkTimeout)
        let getAttendeeCompleted = expectation(description: "get attendee completed")
        Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id) { result in
            switch result {
            case .success(let queriedAttendeeOptional):
                XCTAssertNil(queriedAttendeeOptional)
                getAttendeeCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getAttendeeCompleted], timeout: TestCommonConstants.networkTimeout)
        let getMeetingCompleted = expectation(description: "get meeting completed")
        Amplify.DataStore.query(Meeting8V2.self, byId: meeting.id) { result in
            switch result {
            case .success(let queriedMeetingOptional):
                guard let queriedMeeting = queriedMeetingOptional else {
                    XCTFail("Could not get meeting")
                    return
                }
                XCTAssertEqual(queriedMeeting.attendees?.count, 0)
                getMeetingCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getMeetingCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteMeetingShouldCascadeDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let attendee = saveAttendee(),
              let meeting = saveMeeting(),
              let registration = saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        let deleteReceived = expectation(description: "Delete received")
        deleteReceived.expectedFulfillmentCount = 2 // meeting and registration
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let attendeeEvent = try? mutationEvent.decodeModel() as? Attendee8V2,
                    attendeeEvent.id == attendee.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let meetingEvent = try? mutationEvent.decodeModel() as? Meeting8V2, meetingEvent.id == meeting.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(meetingEvent.title, meeting.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                        return
                    }
                }
                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                    registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)
        let deleteCompleted = expectation(description: "delete completed")
        Amplify.DataStore.delete(Meeting8V2.self, withId: meeting.id) { result in
            switch result {
            case .success:
                deleteCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [deleteCompleted, deleteReceived], timeout: TestCommonConstants.networkTimeout)
        let getAttendeeCompleted = expectation(description: "get attendee completed")
        Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id) { result in
            switch result {
            case .success(let queriedAttendeeOptional):
                guard let queriedAttendee = queriedAttendeeOptional else {
                    XCTFail("Could not get meeting")
                    return
                }
                XCTAssertEqual(queriedAttendee.meetings?.count, 0)
                getAttendeeCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getAttendeeCompleted], timeout: TestCommonConstants.networkTimeout)
        let getMeetingCompleted = expectation(description: "get meeting completed")
        Amplify.DataStore.query(Meeting8V2.self, byId: meeting.id) { result in
            switch result {
            case .success(let queriedMeetingOptional):
                XCTAssertNil(queriedMeetingOptional)

                getMeetingCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getMeetingCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func saveAttendee() -> Attendee8V2? {
        let attendee = Attendee8V2()
        var result: Attendee8V2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(attendee) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveMeeting() -> Meeting8V2? {
        let meeting = Meeting8V2(title: "title")
        var result: Meeting8V2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(meeting) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveRegistration(meeting: Meeting8V2, attendee: Attendee8V2) -> Registration8V2? {
        let registration = Registration8V2(meeting: meeting, attendee: attendee)
        var result: Registration8V2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(registration) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

}
