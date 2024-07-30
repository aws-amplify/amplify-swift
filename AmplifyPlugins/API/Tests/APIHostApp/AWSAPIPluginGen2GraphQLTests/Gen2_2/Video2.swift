// swiftlint:disable all
import Amplify
import Foundation

public struct Video2: Model {
  public let id: String
  public var privacySetting: PrivacySetting2?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      privacySetting: PrivacySetting2? = nil) {
    self.init(id: id,
      privacySetting: privacySetting,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      privacySetting: PrivacySetting2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.privacySetting = privacySetting
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}