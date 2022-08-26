//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

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
        try await startAmplifyAndWaitForSync()
        guard let attendee = await saveAttendee(),
              let meeting = await saveMeeting(),
              let registration = await saveRegistration(meeting: meeting, attendee: attendee) else {
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
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        let queriedAttendeeOptional = try await Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id)
        guard let queriedAttendee = queriedAttendeeOptional else {
            XCTFail("Could not get attendee")
            return
        }
        try await queriedAttendee.meetings?.fetch()
        XCTAssertEqual(queriedAttendee.meetings?.count, 1)
        
        let queriedMeetingOptional = try await Amplify.DataStore.query(Meeting8V2.self, byId: meeting.id)
        guard let queriedMeeting = queriedMeetingOptional else {
            XCTFail("Could not get meeting")
            return
        }
        try await queriedMeeting.attendees?.fetch()
        XCTAssertEqual(queriedMeeting.attendees?.count, 1)
    }

    func testUpdateRegistrationToAnotherAttendee() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard let attendee = await saveAttendee(),
              let attendee2 = await saveAttendee(),
              let meeting = await saveMeeting(),
              var registration = await saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
                  return
              }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 4 // 4 models (2 attendees and 1 meeting and 1 registration)
        var hubListener = Amplify.Hub.listen(
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
                    }
                }
            }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        let updateReceived = expectation(description: "Update notification received")
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                else {
                    XCTFail("Can't cast payload as mutation event")
                    return
                }

                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                   registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        updateReceived.fulfill()
                        return
                    }
                }
            }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        registration.attendee = attendee2
        let updatedRegistration = try await Amplify.DataStore.save(registration)
        XCTAssertEqual(updatedRegistration.attendee.id, attendee2.id)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        var queriedAttendeeOptional = try await Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id)
        guard let queriedAttendee = queriedAttendeeOptional else {
            XCTFail("Could not get attendee")
            return
        }
        try await queriedAttendee.meetings?.fetch()
        XCTAssertEqual(queriedAttendee.meetings?.count, 0)
        
        queriedAttendeeOptional = try await Amplify.DataStore.query(Attendee8V2.self, byId: attendee2.id)
        guard let queriedAttendee = queriedAttendeeOptional else {
            XCTFail("Could not get attendee")
            return
        }
        try await queriedAttendee.meetings?.fetch()
        XCTAssertEqual(queriedAttendee.meetings?.count, 1)
    }

    func testDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard let attendee = await saveAttendee(),
              let meeting = await saveMeeting(),
              let registration = await saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        var hubListener = Amplify.Hub.listen(
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
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        let deleteRegistrationRecieved = expectation(description: "Delete registration received")
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                    registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteRegistrationRecieved.fulfill()
                    }
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let _ = try await Amplify.DataStore.delete(registration)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        let queriedAttendeeOptional = try await Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id)
        guard let queriedAttendee = queriedAttendeeOptional else {
            XCTFail("Could not get attendee")
            return
        }
        try await queriedAttendee.meetings?.fetch()
        XCTAssertEqual(queriedAttendee.meetings?.count, 0)
        
        let queriedMeetingOptional = try await Amplify.DataStore.query(Meeting8V2.self, byId: meeting.id)
        guard let queriedMeeting = queriedMeetingOptional else {
            XCTFail("Could not get meeting")
            return
        }
        try await queriedMeeting.attendees?.fetch()
        XCTAssertEqual(queriedMeeting.attendees?.count, 0)
    }

    func testDeleteAttendeeShouldCascadeDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard let attendee = await saveAttendee(),
              let meeting = await saveMeeting(),
              let registration = await saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        var hubListener = Amplify.Hub.listen(
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
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        let deleteReceived = expectation(description: "Delete received")
        deleteReceived.expectedFulfillmentCount = 2 // attendee and registration
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let attendeeEvent = try? mutationEvent.decodeModel() as? Attendee8V2,
                    attendeeEvent.id == attendee.id {
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
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
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                }
        }
        
        _ = try await Amplify.DataStore.delete(attendee)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        let queriedAttendeeOptional = try await Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id)
        XCTAssertNil(queriedAttendeeOptional)
        
        let queriedMeetingOptional = try await Amplify.DataStore.query(Meeting8V2.self, byId: meeting.id)
        guard let queriedMeeting = queriedMeetingOptional else {
            XCTFail("Could not get meeting")
            return
        }
        try await queriedMeeting.attendees?.fetch()
        XCTAssertEqual(queriedMeeting.attendees?.count, 0)
    }

    func testDeleteMeetingShouldCascadeDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard let attendee = await saveAttendee(),
              let meeting = await saveMeeting(),
              let registration = await saveRegistration(meeting: meeting, attendee: attendee) else {
                  XCTFail("Could not create attendee, meeting, registration")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        var hubListener = Amplify.Hub.listen(
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
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        let deleteReceived = expectation(description: "Delete received")
        deleteReceived.expectedFulfillmentCount = 2 // meeting and registration
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let meetingEvent = try? mutationEvent.decodeModel() as? Meeting8V2, meetingEvent.id == meeting.id {
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                        return
                    }
                }
                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                    registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                }
        }
        
        _ = try await Amplify.DataStore.delete(meeting)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        let queriedAttendeeOptional = try await Amplify.DataStore.query(Attendee8V2.self, byId: attendee.id)
        guard let queriedAttendee = queriedAttendeeOptional else {
            XCTFail("Could not get meeting")
            return
        }
        try await queriedAttendee.meetings?.fetch()
        XCTAssertEqual(queriedAttendee.meetings?.count, 0)
        
        let queriedMeetingOptional = try await Amplify.DataStore.query(Meeting8V2.self, byId: meeting.id)
        XCTAssertNil(queriedMeetingOptional)
    }

    func saveAttendee() async -> Attendee8V2? {
        let attendee = Attendee8V2()
        var result: Attendee8V2?
        do {
            result = try await Amplify.DataStore.save(attendee)
        } catch(let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }

    func saveMeeting() async -> Meeting8V2? {
        let meeting = Meeting8V2(title: "title")
        var result: Meeting8V2?
        do {
            result = try await Amplify.DataStore.save(meeting)
        } catch(let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }

    func saveRegistration(meeting: Meeting8V2, attendee: Attendee8V2) async -> Registration8V2? {
        let registration = Registration8V2(meeting: meeting, attendee: attendee)
        var result: Registration8V2?
        do {
            result = try await Amplify.DataStore.save(registration)
        } catch(let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }

}
