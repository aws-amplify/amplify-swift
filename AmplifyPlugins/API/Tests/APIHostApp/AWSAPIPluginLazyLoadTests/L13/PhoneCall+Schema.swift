//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PhoneCall {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case caller
    case callee
    case transcript
    case createdAt
    case updatedAt
    case phoneCallTranscriptId
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let phoneCall = PhoneCall.keys

    model.pluralName = "PhoneCalls"

    model.attributes(
      .index(fields: ["callerId"], name: "byCaller"),
      .index(fields: ["calleeId"], name: "byCallee"),
      .primaryKey(fields: [phoneCall.id])
    )

    model.fields(
      .field(phoneCall.id, is: .required, ofType: .string),
      .belongsTo(phoneCall.caller, is: .required, ofType: Person.self, targetNames: ["callerId"]),
      .belongsTo(phoneCall.callee, is: .required, ofType: Person.self, targetNames: ["calleeId"]),
      .hasOne(phoneCall.transcript, is: .optional, ofType: Transcript.self, associatedWith: Transcript.keys.phoneCall, targetNames: ["phoneCallTranscriptId"]),
      .field(phoneCall.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(phoneCall.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(phoneCall.phoneCallTranscriptId, is: .optional, ofType: .string)
    )
    }
    class Path: ModelPath<PhoneCall> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension PhoneCall: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == PhoneCall {
  var id: FieldPath<String>   {
      string("id")
    }
  var caller: ModelPath<Person>   {
      Person.Path(name: "caller", parent: self)
    }
  var callee: ModelPath<Person>   {
      Person.Path(name: "callee", parent: self)
    }
  var transcript: ModelPath<Transcript>   {
      Transcript.Path(name: "transcript", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
  var phoneCallTranscriptId: FieldPath<String>   {
      string("phoneCallTranscriptId")
    }
}
