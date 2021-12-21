//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Registration8V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case meeting
    case attendee
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let registration8V2 = Registration8V2.keys

    model.pluralName = "Registration8V2s"

    model.attributes(
      .index(fields: ["meetingId", "attendeeId"], name: "byMeeting"),
      .index(fields: ["attendeeId", "meetingId"], name: "byAttendee")
    )

    model.fields(
      .id(),
      .belongsTo(registration8V2.meeting, is: .required, ofType: Meeting8V2.self, targetName: "meetingId"),
      .belongsTo(registration8V2.attendee, is: .required, ofType: Attendee8V2.self, targetName: "attendeeId"),
      .field(registration8V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(registration8V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
