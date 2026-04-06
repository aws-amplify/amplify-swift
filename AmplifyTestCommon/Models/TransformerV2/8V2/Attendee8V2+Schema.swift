//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Attendee8V2 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case meetings
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let attendee8V2 = Attendee8V2.keys

    model.pluralName = "Attendee8V2s"

    model.fields(
      .id(),
      .hasMany(attendee8V2.meetings, is: .optional, ofType: Registration8V2.self, associatedWith: Registration8V2.keys.attendee),
      .field(attendee8V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(attendee8V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
