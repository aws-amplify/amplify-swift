// swiftlint:disable all
import Amplify
import Foundation

public struct Team: Model {
  public let id: String
  public var name: String
  
  public init(id: String = UUID().uuidString,
      name: String) {
      self.id = id
      self.name = name
  }
}