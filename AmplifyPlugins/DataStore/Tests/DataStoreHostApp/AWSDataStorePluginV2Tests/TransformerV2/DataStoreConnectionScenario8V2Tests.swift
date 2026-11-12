//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

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
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class DataStoreConnectionScenario8V2Tests: SyncEngineIntegrationV2TestBase, @unchecked Sendable {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Meeting8V2.self)
            registry.register(modelType: Attendee8V2.self)
            registry.register(modelType: Registration8V2.self)
        }

        let version: String = "1"
    }

    /// Saving a registration syncs it with its attendee and meeting
    ///
    /// - Given: DataStore is ready
    /// - When:
    ///    - An attendee, a meeting and a registration linking them are saved
    /// - Then:
    ///    - A `syncReceived` create with version 1 is received for each of the three models
    ///    - The attendee and the meeting each have one registration
    ///
    func testSaveRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let attendee = Attendee8V2()
        let meeting = Meeting8V2(title: "title")
        let registration = Registration8V2(meeting: meeting, attendee: attendee)
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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
        // Save only once listening, or a fast sync can arrive before the listener exists
        guard await saveAttendee(attendee) != nil,
              await saveMeeting(meeting) != nil,
              await saveRegistration(registration) != nil
        else {
            XCTFail("Could not create attendee, meeting, registration")
            return
        }
        await fulfillment(of: [createReceived], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

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

    /// Moving a registration to another attendee syncs the update
    ///
    /// - Given: DataStore is ready
    /// - When:
    ///    - Two attendees, a meeting and a registration for the first attendee are saved
    ///    - The registration is updated to the second attendee
    /// - Then:
    ///    - A `syncReceived` create with version 1 is received for each of the four models
    ///    - A `syncReceived` update with version 2 is received for the registration
    ///    - The first attendee has no registrations and the second has one
    ///
    func testUpdateRegistrationToAnotherAttendee() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let attendee = Attendee8V2()
        let attendee2 = Attendee8V2()
        let meeting = Meeting8V2(title: "title")
        let registration = Registration8V2(meeting: meeting, attendee: attendee)
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 4 // 4 models (2 attendees and 1 meeting and 1 registration)
        var hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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
        // Save only once listening, or a fast sync can arrive before the listener exists
        guard await saveAttendee(attendee) != nil,
              await saveAttendee(attendee2) != nil,
              await saveMeeting(meeting) != nil,
              await saveRegistration(registration) != nil
        else {
            XCTFail("Could not create attendee, meeting, registration")
            return
        }
        await fulfillment(of: [createReceived], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

        let updateReceived = expectation(description: "Update notification received")
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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

        var registrationToUpdate = registration
        registrationToUpdate.attendee = attendee2
        let updatedRegistration = try await Amplify.DataStore.save(registrationToUpdate)
        XCTAssertEqual(updatedRegistration.attendee.id, attendee2.id)
        await fulfillment(of: [updateReceived], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

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

    /// Deleting a registration syncs the delete
    ///
    /// - Given: DataStore is ready
    /// - When:
    ///    - An attendee, a meeting and a registration linking them are saved
    ///    - The registration is deleted
    /// - Then:
    ///    - A `syncReceived` create with version 1 is received for each of the three models
    ///    - A `syncReceived` delete with version 2 is received for the registration
    ///    - The attendee and the meeting have no registrations
    ///
    func testDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let attendee = Attendee8V2()
        let meeting = Meeting8V2(title: "title")
        let registration = Registration8V2(meeting: meeting, attendee: attendee)
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        var hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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
        // Save only once listening, or a fast sync can arrive before the listener exists
        guard await saveAttendee(attendee) != nil,
              await saveMeeting(meeting) != nil,
              await saveRegistration(registration) != nil
        else {
            XCTFail("Could not create attendee, meeting, registration")
            return
        }
        await fulfillment(of: [createReceived], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

        let deleteRegistrationRecieved = expectation(description: "Delete registration received")
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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
        _ = try await Amplify.DataStore.delete(registration)
        await fulfillment(of: [deleteRegistrationRecieved], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

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

    /// Deleting an attendee cascades to its registration
    ///
    /// - Given: DataStore is ready
    /// - When:
    ///    - An attendee, a meeting and a registration linking them are saved
    ///    - The attendee is deleted
    /// - Then:
    ///    - A `syncReceived` create with version 1 is received for each of the three models
    ///    - A `syncReceived` delete with version 2 is received for the attendee and the registration
    ///    - The attendee is gone and the meeting has no registrations
    ///
    func testDeleteAttendeeShouldCascadeDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let attendee = Attendee8V2()
        let meeting = Meeting8V2(title: "title")
        let registration = Registration8V2(meeting: meeting, attendee: attendee)
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        var hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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
        // Save only once listening, or a fast sync can arrive before the listener exists
        guard await saveAttendee(attendee) != nil,
              await saveMeeting(meeting) != nil,
              await saveRegistration(registration) != nil
        else {
            XCTFail("Could not create attendee, meeting, registration")
            return
        }
        await fulfillment(of: [createReceived], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

        let deleteReceived = expectation(description: "Delete received")
        deleteReceived.expectedFulfillmentCount = 2 // attendee and registration
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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
                if let registrationEvent = try? mutationEvent.decodeModel() as? Registration8V2,
                    registrationEvent.id == registration.id {
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.delete(attendee)
        await fulfillment(of: [deleteReceived], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

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

    /// Deleting a meeting cascades to its registration
    ///
    /// - Given: DataStore is ready
    /// - When:
    ///    - An attendee, a meeting and a registration linking them are saved
    ///    - The meeting is deleted
    /// - Then:
    ///    - A `syncReceived` create with version 1 is received for each of the three models
    ///    - A `syncReceived` delete with version 2 is received for the meeting and the registration
    ///    - The meeting is gone and the attendee has no registrations
    ///
    func testDeleteMeetingShouldCascadeDeleteRegistration() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let attendee = Attendee8V2()
        let meeting = Meeting8V2(title: "title")
        let registration = Registration8V2(meeting: meeting, attendee: attendee)
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 attendee and 1 meeting and 1 registration)
        var hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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
        // Save only once listening, or a fast sync can arrive before the listener exists
        guard await saveAttendee(attendee) != nil,
              await saveMeeting(meeting) != nil,
              await saveRegistration(registration) != nil
        else {
            XCTFail("Could not create attendee, meeting, registration")
            return
        }
        await fulfillment(of: [createReceived], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

        let deleteReceived = expectation(description: "Delete received")
        deleteReceived.expectedFulfillmentCount = 2 // meeting and registration
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.delete(meeting)
        await fulfillment(of: [deleteReceived], timeout: networkTimeout)
        Amplify.Hub.removeListener(hubListener)

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

    func saveAttendee(_ attendee: Attendee8V2 = Attendee8V2()) async -> Attendee8V2? {
        var result: Attendee8V2?
        do {
            result = try await Amplify.DataStore.save(attendee)
        } catch (let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }

    func saveMeeting(_ meeting: Meeting8V2 = Meeting8V2(title: "title")) async -> Meeting8V2? {
        var result: Meeting8V2?
        do {
            result = try await Amplify.DataStore.save(meeting)
        } catch (let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }

    func saveRegistration(_ registration: Registration8V2) async -> Registration8V2? {
        var result: Registration8V2?
        do {
            result = try await Amplify.DataStore.save(registration)
        } catch (let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }

}
