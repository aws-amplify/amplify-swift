// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "c8f7b72ad6040a2f04d1500f59aa83e0"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Post.self)
  }
}