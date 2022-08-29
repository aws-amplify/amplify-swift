//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Meeting8V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case attendees
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let meeting8V2 = Meeting8V2.keys

    model.pluralName = "Meeting8V2s"

    model.fields(
      .id(),
      .field(meeting8V2.title, is: .required, ofType: .string),
      .hasMany(meeting8V2.attendees, is: .optional, ofType: Registration8V2.self, associatedWith: Registration8V2.keys.meeting),
      .field(meeting8V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(meeting8V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
