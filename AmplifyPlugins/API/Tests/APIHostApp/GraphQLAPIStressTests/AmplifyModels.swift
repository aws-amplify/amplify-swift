// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol.

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "5ee542e5c6ab0424a858288c724b1322"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Post.self)
    ModelRegistry.register(modelType: Comment.self)
  }
}
