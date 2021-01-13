// swiftlint:disable all
import Amplify
import Foundation

public struct M2MPost: Model {
  public let id: String
  public var title: String
  public var editors: List<M2MPostEditor>?
  
  public init(id: String = UUID().uuidString,
      title: String,
      editors: List<M2MPostEditor>? = []) {
      self.id = id
      self.title = title
      self.editors = editors
  }
}