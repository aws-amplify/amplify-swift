//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Transcript: Model {
  public let id: String
  public var text: String
  public var language: String?
  var _phoneCall: LazyReference<PhoneCall>
  public var phoneCall: PhoneCall?   {
      get async throws {
        try await _phoneCall.get()
      }
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    id: String = UUID().uuidString,
    text: String,
    language: String? = nil,
    phoneCall: PhoneCall? = nil
  ) {
    self.init(
      id: id,
      text: text,
      language: language,
      phoneCall: phoneCall,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    text: String,
    language: String? = nil,
    phoneCall: PhoneCall? = nil,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.text = text
      self.language = language
      self._phoneCall = LazyReference(phoneCall)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setPhoneCall(_ phoneCall: PhoneCall? = nil) {
    _phoneCall = LazyReference(phoneCall)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try values.decode(String.self, forKey: .id)
      self.text = try values.decode(String.self, forKey: .text)
      self.language = try? values.decode(String?.self, forKey: .language)
      self._phoneCall = try values.decodeIfPresent(LazyReference<PhoneCall>.self, forKey: .phoneCall) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(text, forKey: .text)
      try container.encode(language, forKey: .language)
      try container.encode(_phoneCall, forKey: .phoneCall)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
