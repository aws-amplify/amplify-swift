// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "337d729dc13588a18a9fbd79c5f7b068"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Post4V2.self)
    ModelRegistry.register(modelType: Comment4V2.self)
  }
}