//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Attendee8V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case meetings
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
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
