//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Transcript {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case text
    case language
    case phoneCall
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let transcript = Transcript.keys

    model.pluralName = "Transcripts"

    model.attributes(
      .primaryKey(fields: [transcript.id])
    )

    model.fields(
      .field(transcript.id, is: .required, ofType: .string),
      .field(transcript.text, is: .required, ofType: .string),
      .field(transcript.language, is: .optional, ofType: .string),
      .belongsTo(transcript.phoneCall, is: .optional, ofType: PhoneCall.self, targetNames: ["transcriptPhoneCallId"]),
      .field(transcript.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(transcript.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Transcript> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Transcript: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Transcript {
  var id: FieldPath<String>   {
      string("id")
    }
  var text: FieldPath<String>   {
      string("text")
    }
  var language: FieldPath<String>   {
      string("language")
    }
  var phoneCall: ModelPath<PhoneCall>   {
      PhoneCall.Path(name: "phoneCall", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
