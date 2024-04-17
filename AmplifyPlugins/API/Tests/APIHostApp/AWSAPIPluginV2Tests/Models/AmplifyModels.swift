// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "165944a36979cd395e3b22145bbfeff0"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Blog.self)
    ModelRegistry.register(modelType: Post.self)
    ModelRegistry.register(modelType: Comment.self)
  }
}
