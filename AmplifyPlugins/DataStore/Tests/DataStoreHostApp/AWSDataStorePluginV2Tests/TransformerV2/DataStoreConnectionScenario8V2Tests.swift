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
        let attendee = try await createModelUntilSynced(data: randomAttendee())
        let meeting = try await createModelUntilSynced(data: randomMeeting())
        try await createModelUntilSynced(data: randomRegistration(meeting: meeting, attendee: attendee))

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
        let attendee = try await createModelUntilSynced(data: randomAttendee())
        let attendee2 = try await createModelUntilSynced(data: randomAttendee())
        let meeting = try await createModelUntilSynced(data: randomMeeting())
        var registration = try await createModelUntilSynced(data: randomRegistration(meeting: meeting, attendee: attendee))

        registration.attendee = attendee2
        let updatedRegistration = try await updateModelWaitForSync(data: registration, isEqual: { $0.identifier == $1.identifier })
        XCTAssertEqual(updatedRegistration.attendee.id, attendee2.id)

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
        let attendee = try await createModelUntilSynced(data: randomAttendee())
        let meeting = try await createModelUntilSynced(data: randomMeeting())
        let registration = try await createModelUntilSynced(data: randomRegistration(meeting: meeting, attendee: attendee))

        let _ = try await deleteModelWaitForSync(data: registration)

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
        let attendee = try await createModelUntilSynced(data: randomAttendee())
        let meeting = try await createModelUntilSynced(data: randomMeeting())
        try await createModelUntilSynced(data: randomRegistration(meeting: meeting, attendee: attendee))

        _ = try await deleteModelWaitForSync(data: attendee)

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
        let attendee = try await createModelUntilSynced(data: randomAttendee())
        let meeting = try await createModelUntilSynced(data: randomMeeting())
        try await createModelUntilSynced(data: randomRegistration(meeting: meeting, attendee: attendee))

        _ = try await deleteModelWaitForSync(data: meeting)

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

    private func randomAttendee() -> Attendee8V2 {
        Attendee8V2()
    }

    private func randomMeeting() -> Meeting8V2 {
        Meeting8V2(title: UUID().uuidString)
    }

    private func randomRegistration(meeting: Meeting8V2, attendee: Attendee8V2) -> Registration8V2 {
        Registration8V2(meeting: meeting, attendee: attendee)
    }
}
